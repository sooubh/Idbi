const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, PutCommand, GetCommand, QueryCommand, DeleteCommand } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({ region: process.env.AWS_REGION || "ap-south-1" });
const ddbDocClient = DynamoDBDocumentClient.from(client);
const TABLE_NAME = process.env.TABLE_NAME || "WealthData";

exports.handler = async (event) => {
  console.log("Event received:", JSON.stringify(event));

  const path = event.path;
  const method = event.httpMethod;
  const query = event.queryStringParameters || {};
  let body = {};
  if (event.body) {
    try {
      body = JSON.parse(event.body);
    } catch (e) {
      console.error("JSON parse error:", e);
    }
  }

  const responseHeaders = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type,Authorization",
    "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS"
  };

  if (method === "OPTIONS") {
    return {
      statusCode: 200,
      headers: responseHeaders,
      body: ""
    };
  }

  try {
    // 1. Transactions GET /transactions?userId=xxx&limit=yyy
    if (path === "/transactions" && method === "GET") {
      const userId = query.userId;
      const limit = parseInt(query.limit || "60", 10);
      if (!userId) return errorResponse("userId is required", 400, responseHeaders);

      const res = await ddbDocClient.send(new QueryCommand({
        TableName: TABLE_NAME,
        KeyConditionExpression: "PK = :pk AND begins_with(SK, :sk)",
        ExpressionAttributeValues: {
          ":pk": `USER#${userId}`,
          ":sk": "TRANSACTION#"
        }
      }));

      const txs = (res.Items || []).map(item => ({
        id: item.SK.replace("TRANSACTION#", ""),
        ...item.data
      }));

      // Sort descending by transactionAt
      txs.sort((a, b) => new Date(b.transactionAt).getTime() - new Date(a.transactionAt).getTime());

      return successResponse(txs.slice(0, limit), responseHeaders);
    }

    // 2. Transactions POST /transactions
    if (path === "/transactions" && method === "POST") {
      const { id, userId, accountId, amount, type } = body;
      if (!id || !userId || !accountId) return errorResponse("Missing required fields", 400, responseHeaders);

      // Save transaction
      await ddbDocClient.send(new PutCommand({
        TableName: TABLE_NAME,
        Item: {
          PK: `USER#${userId}`,
          SK: `TRANSACTION#${id}`,
          data: body
        }
      }));

      // Update account balance
      const accountRes = await ddbDocClient.send(new GetCommand({
        TableName: TABLE_NAME,
        Key: {
          PK: `USER#${userId}`,
          SK: `ACCOUNT#${accountId}`
        }
      }));

      if (accountRes.Item) {
        const account = accountRes.Item.data;
        const delta = type === "expense" ? -amount : amount;
        account.balance = (account.balance || 0) + delta;
        account.updatedAt = new Date().toISOString();

        await ddbDocClient.send(new PutCommand({
          TableName: TABLE_NAME,
          Item: {
            PK: `USER#${userId}`,
            SK: `ACCOUNT#${accountId}`,
            data: account
          }
        }));
      }

      return successResponse({ success: true }, responseHeaders);
    }

    // 3. Transactions delete POST /transactions/delete
    if (path === "/transactions/delete" && method === "POST") {
      const { userId, transactionId, accountId } = body;
      if (!userId || !transactionId || !accountId) return errorResponse("Missing required fields", 400, responseHeaders);

      // Get transaction first to know amount and type
      const txRes = await ddbDocClient.send(new GetCommand({
        TableName: TABLE_NAME,
        Key: {
          PK: `USER#${userId}`,
          SK: `TRANSACTION#${transactionId}`
        }
      }));

      if (txRes.Item) {
        const tx = txRes.Item.data;
        const amount = tx.amount || 0;
        const type = tx.type;

        // Delete transaction
        await ddbDocClient.send(new DeleteCommand({
          TableName: TABLE_NAME,
          Key: {
            PK: `USER#${userId}`,
            SK: `TRANSACTION#${transactionId}`
          }
        }));

        // Reverse account balance update
        const accountRes = await ddbDocClient.send(new GetCommand({
          TableName: TABLE_NAME,
          Key: {
            PK: `USER#${userId}`,
            SK: `ACCOUNT#${accountId}`
          }
        }));

        if (accountRes.Item) {
          const account = accountRes.Item.data;
          const delta = type === "expense" ? amount : -amount;
          account.balance = (account.balance || 0) + delta;
          account.updatedAt = new Date().toISOString();

          await ddbDocClient.send(new PutCommand({
            TableName: TABLE_NAME,
            Item: {
              PK: `USER#${userId}`,
              SK: `ACCOUNT#${accountId}`,
              data: account
            }
          }));
        }
      }

      return successResponse({ success: true }, responseHeaders);
    }

    // 4. Transactions override category POST /transactions/override-category
    if (path === "/transactions/override-category" && method === "POST") {
      const { userId, transactionId, category } = body;
      if (!userId || !transactionId || !category) return errorResponse("Missing required fields", 400, responseHeaders);

      const txRes = await ddbDocClient.send(new GetCommand({
        TableName: TABLE_NAME,
        Key: {
          PK: `USER#${userId}`,
          SK: `TRANSACTION#${transactionId}`
        }
      }));

      if (txRes.Item) {
        const tx = txRes.Item.data;
        tx.category = category;
        tx.isCategoryOverridden = true;
        tx.updatedAt = new Date().toISOString();

        await ddbDocClient.send(new PutCommand({
          TableName: TABLE_NAME,
          Item: {
            PK: `USER#${userId}`,
            SK: `TRANSACTION#${transactionId}`,
            data: tx
          }
        }));
      }

      return successResponse({ success: true }, responseHeaders);
    }

    // 5. Accounts GET /accounts?userId=xxx
    if (path === "/accounts" && method === "GET") {
      const userId = query.userId;
      if (!userId) return errorResponse("userId is required", 400, responseHeaders);

      const res = await ddbDocClient.send(new QueryCommand({
        TableName: TABLE_NAME,
        KeyConditionExpression: "PK = :pk AND begins_with(SK, :sk)",
        ExpressionAttributeValues: {
          ":pk": `USER#${userId}`,
          ":sk": "ACCOUNT#"
        }
      }));

      const accounts = (res.Items || []).map(item => ({
        id: item.SK.replace("ACCOUNT#", ""),
        ...item.data
      }));

      return successResponse(accounts, responseHeaders);
    }

    // 6. Accounts POST /accounts
    if (path === "/accounts" && method === "POST") {
      const { id, userId } = body;
      if (!id || !userId) return errorResponse("Missing id or userId", 400, responseHeaders);

      await ddbDocClient.send(new PutCommand({
        TableName: TABLE_NAME,
        Item: {
          PK: `USER#${userId}`,
          SK: `ACCOUNT#${id}`,
          data: body
        }
      }));

      return successResponse({ success: true }, responseHeaders);
    }

    // 7. Accounts archive POST /accounts/archive
    if (path === "/accounts/archive" && method === "POST") {
      const { userId, accountId } = body;
      if (!userId || !accountId) return errorResponse("Missing fields", 400, responseHeaders);

      const accountRes = await ddbDocClient.send(new GetCommand({
        TableName: TABLE_NAME,
        Key: {
          PK: `USER#${userId}`,
          SK: `ACCOUNT#${accountId}`
        }
      }));

      if (accountRes.Item) {
        const account = accountRes.Item.data;
        account.isActive = false;
        account.updatedAt = new Date().toISOString();

        await ddbDocClient.send(new PutCommand({
          TableName: TABLE_NAME,
          Item: {
            PK: `USER#${userId}`,
            SK: `ACCOUNT#${accountId}`,
            data: account
          }
        }));
      }

      return successResponse({ success: true }, responseHeaders);
    }

    // 8. Accounts unified balance GET /accounts/unified-balance?userId=xxx
    if (path === "/accounts/unified-balance" && method === "GET") {
      const userId = query.userId;
      if (!userId) return errorResponse("userId is required", 400, responseHeaders);

      const res = await ddbDocClient.send(new QueryCommand({
        TableName: TABLE_NAME,
        KeyConditionExpression: "PK = :pk AND begins_with(SK, :sk)",
        ExpressionAttributeValues: {
          ":pk": `USER#${userId}`,
          ":sk": "ACCOUNT#"
        }
      }));

      const activeAccounts = (res.Items || [])
        .map(item => item.data)
        .filter(account => account.isActive !== false);

      const balance = activeAccounts.reduce((sum, account) => sum + (account.balance || 0), 0);

      return successResponse({ balance }, responseHeaders);
    }

    // 9. Goals GET /goals?userId=xxx
    if (path === "/goals" && method === "GET") {
      const userId = query.userId;
      if (!userId) return errorResponse("userId is required", 400, responseHeaders);

      const res = await ddbDocClient.send(new QueryCommand({
        TableName: TABLE_NAME,
        KeyConditionExpression: "PK = :pk AND begins_with(SK, :sk)",
        ExpressionAttributeValues: {
          ":pk": `USER#${userId}`,
          ":sk": "GOAL#"
        }
      }));

      const goals = (res.Items || []).map(item => ({
        id: item.SK.replace("GOAL#", ""),
        ...item.data
      }));

      return successResponse(goals, responseHeaders);
    }

    // 10. Goals POST /goals
    if (path === "/goals" && method === "POST") {
      const { id, userId } = body;
      if (!id || !userId) return errorResponse("Missing id or userId", 400, responseHeaders);

      await ddbDocClient.send(new PutCommand({
        TableName: TABLE_NAME,
        Item: {
          PK: `USER#${userId}`,
          SK: `GOAL#${id}`,
          data: body
        }
      }));

      return successResponse({ success: true }, responseHeaders);
    }

    // 11. Goals contribute POST /goals/contribute
    if (path === "/goals/contribute" && method === "POST") {
      const { userId, goalId, amount } = body;
      if (!userId || !goalId || !amount) return errorResponse("Missing fields", 400, responseHeaders);

      const goalRes = await ddbDocClient.send(new GetCommand({
        TableName: TABLE_NAME,
        Key: {
          PK: `USER#${userId}`,
          SK: `GOAL#${goalId}`
        }
      }));

      if (goalRes.Item) {
        const goal = goalRes.Item.data;
        goal.savedAmount = (goal.savedAmount || 0) + amount;
        goal.status = goal.savedAmount >= goal.targetAmount ? "achieved" : "active";
        goal.updatedAt = new Date().toISOString();

        await ddbDocClient.send(new PutCommand({
          TableName: TABLE_NAME,
          Item: {
            PK: `USER#${userId}`,
            SK: `GOAL#${goalId}`,
            data: goal
          }
        }));
      }

      return successResponse({ success: true }, responseHeaders);
    }

    // 12. Splits groups GET /splits/groups?userId=xxx
    if (path === "/splits/groups" && method === "GET") {
      const userId = query.userId;
      if (!userId) return errorResponse("userId is required", 400, responseHeaders);

      // 1. Find group member maps
      const memberMaps = await ddbDocClient.send(new QueryCommand({
        TableName: TABLE_NAME,
        KeyConditionExpression: "PK = :pk AND begins_with(SK, :sk)",
        ExpressionAttributeValues: {
          ":pk": `USER#${userId}`,
          ":sk": "GROUP_MEMBER#"
        }
      }));

      const groupIds = (memberMaps.Items || []).map(item => item.SK.replace("GROUP_MEMBER#", ""));
      const groups = [];

      for (const groupId of groupIds) {
        const groupRes = await ddbDocClient.send(new GetCommand({
          TableName: TABLE_NAME,
          Key: {
            PK: `GROUP#${groupId}`,
            SK: "METADATA"
          }
        }));
        if (groupRes.Item) {
          groups.push({
            id: groupId,
            ...groupRes.Item.data
          });
        }
      }

      return successResponse(groups, responseHeaders);
    }

    // 13. Splits groups POST /splits/groups
    if (path === "/splits/groups" && method === "POST") {
      const { id, ownerId, memberIds } = body;
      if (!id || !ownerId || !memberIds) return errorResponse("Missing fields", 400, responseHeaders);

      // Save group metadata
      await ddbDocClient.send(new PutCommand({
        TableName: TABLE_NAME,
        Item: {
          PK: `GROUP#${id}`,
          SK: "METADATA",
          data: body
        }
      }));

      // Map group for each member
      for (const memberId of memberIds) {
        await ddbDocClient.send(new PutCommand({
          TableName: TABLE_NAME,
          Item: {
            PK: `USER#${memberId}`,
            SK: `GROUP_MEMBER#${id}`
          }
        }));
      }

      return successResponse({ success: true }, responseHeaders);
    }

    // 14. Splits expenses GET /splits/expenses?userId=xxx&groupId=yyy
    if (path === "/splits/expenses" && method === "GET") {
      const { groupId } = query;
      if (!groupId) return errorResponse("groupId is required", 400, responseHeaders);

      const res = await ddbDocClient.send(new QueryCommand({
        TableName: TABLE_NAME,
        KeyConditionExpression: "PK = :pk AND begins_with(SK, :sk)",
        ExpressionAttributeValues: {
          ":pk": `GROUP#${groupId}`,
          ":sk": "EXPENSE#"
        }
      }));

      const expenses = (res.Items || []).map(item => ({
        id: item.SK.replace("EXPENSE#", ""),
        ...item.data
      }));

      // Sort descending by expenseAt
      expenses.sort((a, b) => new Date(b.expenseAt).getTime() - new Date(a.expenseAt).getTime());

      return successResponse(expenses, responseHeaders);
    }

    // 15. Splits expenses POST /splits/expenses
    if (path === "/splits/expenses" && method === "POST") {
      const { id, groupId } = body;
      if (!id || !groupId) return errorResponse("Missing fields", 400, responseHeaders);

      await ddbDocClient.send(new PutCommand({
        TableName: TABLE_NAME,
        Item: {
          PK: `GROUP#${groupId}`,
          SK: `EXPENSE#${id}`,
          data: body
        }
      }));

      return successResponse({ success: true }, responseHeaders);
    }

    // 16. Splits expenses settle POST /splits/expenses/settle
    if (path === "/splits/expenses/settle" && method === "POST") {
      const { userId, expenseId } = body;
      if (!userId || !expenseId) return errorResponse("Missing fields", 400, responseHeaders);

      // Find the expense. Since PK is GROUP#<groupId> and SK is EXPENSE#<expenseId>, we have to query or scan if we don't know the groupId.
      // But we can check group IDs of user first.
      const memberMaps = await ddbDocClient.send(new QueryCommand({
        TableName: TABLE_NAME,
        KeyConditionExpression: "PK = :pk AND begins_with(SK, :sk)",
        ExpressionAttributeValues: {
          ":pk": `USER#${userId}`,
          ":sk": "GROUP_MEMBER#"
        }
      }));

      const groupIds = (memberMaps.Items || []).map(item => item.SK.replace("GROUP_MEMBER#", ""));
      let updated = false;

      for (const groupId of groupIds) {
        const expRes = await ddbDocClient.send(new GetCommand({
          TableName: TABLE_NAME,
          Key: {
            PK: `GROUP#${groupId}`,
            SK: `EXPENSE#${expenseId}`
          }
        }));

        if (expRes.Item) {
          const expense = expRes.Item.data;
          expense.status = "settled";
          expense.updatedAt = new Date().toISOString();

          await ddbDocClient.send(new PutCommand({
            TableName: TABLE_NAME,
            Item: {
              PK: `GROUP#${groupId}`,
              SK: `EXPENSE#${expenseId}`,
              data: expense
            }
          }));
          updated = true;
          break;
        }
      }

      return successResponse({ success: updated }, responseHeaders);
    }

    // 17. Insights GET /insights?userId=xxx
    if (path === "/insights" && method === "GET") {
      const userId = query.userId;
      if (!userId) return errorResponse("userId is required", 400, responseHeaders);

      const res = await ddbDocClient.send(new QueryCommand({
        TableName: TABLE_NAME,
        KeyConditionExpression: "PK = :pk AND begins_with(SK, :sk)",
        ExpressionAttributeValues: {
          ":pk": `USER#${userId}`,
          ":sk": "INSIGHT#"
        }
      }));

      const insights = (res.Items || []).map(item => ({
        id: item.SK.replace("INSIGHT#", ""),
        ...item.data
      }));

      return successResponse(insights, responseHeaders);
    }

    // 18. Insights POST /insights
    if (path === "/insights" && method === "POST") {
      const { userId, insights } = body;
      if (!userId || !insights || !Array.isArray(insights)) return errorResponse("Missing fields", 400, responseHeaders);

      for (const insight of insights) {
        await ddbDocClient.send(new PutCommand({
          TableName: TABLE_NAME,
          Item: {
            PK: `USER#${userId}`,
            SK: `INSIGHT#${insight.id}`,
            data: insight
          }
        }));
      }

      return successResponse({ success: true }, responseHeaders);
    }

    // 19. Preferences GET /preferences?userId=xxx
    if (path === "/preferences" && method === "GET") {
      const userId = query.userId;
      if (!userId) return errorResponse("userId is required", 400, responseHeaders);

      const res = await ddbDocClient.send(new QueryCommand({
        TableName: TABLE_NAME,
        KeyConditionExpression: "PK = :pk AND begins_with(SK, :sk)",
        ExpressionAttributeValues: {
          ":pk": `USER#${userId}`,
          ":sk": "PREF_"
        }
      }));

      const preferences = {};
      for (const item of (res.Items || [])) {
        const type = item.SK.replace("PREF_", "");
        preferences[type] = item.data;
      }

      return successResponse(preferences, responseHeaders);
    }

    // 20. Preferences daily reminder POST /preferences/daily-reminder
    if (path === "/preferences/daily-reminder" && method === "POST") {
      const { userId, enabled, localTime, updatedAt } = body;
      if (!userId) return errorResponse("userId is required", 400, responseHeaders);

      await ddbDocClient.send(new PutCommand({
        TableName: TABLE_NAME,
        Item: {
          PK: `USER#${userId}`,
          SK: "PREF_daily_spend",
          data: { enabled, localTime, updatedAt }
        }
      }));

      return successResponse({ success: true }, responseHeaders);
    }

    // 21. Preferences budget alert POST /preferences/budget-alert
    if (path === "/preferences/budget-alert" && method === "POST") {
      const { userId, enabled, monthlyLimit, updatedAt } = body;
      if (!userId) return errorResponse("userId is required", 400, responseHeaders);

      await ddbDocClient.send(new PutCommand({
        TableName: TABLE_NAME,
        Item: {
          PK: `USER#${userId}`,
          SK: "PREF_budget_alert",
          data: { enabled, monthlyLimit, updatedAt }
        }
      }));

      return successResponse({ success: true }, responseHeaders);
    }

    // 22. Seed POST /seed
    if (path === "/seed" && method === "POST") {
      const { userId } = body;
      if (!userId) return errorResponse("userId is required", 400, responseHeaders);

      // Seed dummy starter accounts, goals, and transactions
      const now = new Date();
      
      const seedAccounts = [
        { name: "SBI Savings", type: "bank", provider: "SBI", balance: 4200 },
        { name: "PhonePe Wallet", type: "upi", provider: "PhonePe", balance: 1300 },
        { name: "Cash in Hand", type: "cash", provider: "Wallet", balance: 650 }
      ];

      const seedGoals = [
        { title: "Emergency fund", targetAmount: 10000, savedAmount: 2500, deadlineDays: 120 }
      ];

      const seedTransactions = [
        { title: "Monthly stipend", amount: 5500, type: "income", category: "stipend", source: "bank transfer", channel: "bank_transfer" },
        { title: "Mess bill", amount: 1200, type: "expense", category: "food", source: "Google Pay", channel: "upi" },
        { title: "Freelance payout", amount: 3000, type: "income", category: "freelance", source: "bank transfer", channel: "bank_transfer" },
        { title: "Groceries - Dmart", amount: 980, type: "expense", category: "grocery", source: "PhonePe", channel: "upi" },
        { title: "Metro Recharge", amount: 450, type: "expense", category: "travel", source: "Paytm", channel: "upi" },
        { title: "Tea and Snacks", amount: 120, type: "expense", category: "food", source: "Cash", channel: "cash" },
        { title: "Online Shopping", amount: 1890, type: "expense", category: "shopping", source: "Amazon Pay", channel: "upi" },
        { title: "Pharmacy", amount: 420, type: "expense", category: "health", source: "BHIM UPI", channel: "upi" },
        { title: "Fuel", amount: 850, type: "expense", category: "travel", source: "Cash", channel: "cash" },
        { title: "Laptop Accessory", amount: 1299, type: "expense", category: "shopping", source: "HDFC Debit Card", channel: "card" }
      ];

      // 1. Create accounts
      const accounts = [];
      for (let i = 0; i < seedAccounts.length; i++) {
        const accId = `acc_seed_${i}_${userId.slice(0, 8)}`;
        const accountItem = {
          id: accId,
          userId: userId,
          name: seedAccounts[i].name,
          type: seedAccounts[i].type,
          provider: seedAccounts[i].provider,
          balance: seedAccounts[i].balance,
          isActive: true,
          icon: seedAccounts[i].type === "bank" ? "account_balance" : (seedAccounts[i].type === "upi" ? "smartphone" : "payments"),
          transactionIds: [],
          createdAt: now.toISOString(),
          updatedAt: now.toISOString()
        };
        
        await ddbDocClient.send(new PutCommand({
          TableName: TABLE_NAME,
          Item: {
            PK: `USER#${userId}`,
            SK: `ACCOUNT#${accId}`,
            data: accountItem
          }
        }));
        accounts.push(accountItem);
      }

      // 2. Create goals
      for (let i = 0; i < seedGoals.length; i++) {
        const goalId = `goal_seed_${i}_${userId.slice(0, 8)}`;
        const deadlineDate = new Date();
        deadlineDate.setDate(deadlineDate.getDate() + seedGoals[i].deadlineDays);

        const goalItem = {
          id: goalId,
          userId: userId,
          title: seedGoals[i].title,
          targetAmount: seedGoals[i].targetAmount,
          savedAmount: seedGoals[i].savedAmount,
          deadline: deadlineDate.toISOString(),
          status: "active",
          priority: i + 1,
          createdAt: now.toISOString(),
          updatedAt: now.toISOString()
        };

        await ddbDocClient.send(new PutCommand({
          TableName: TABLE_NAME,
          Item: {
            PK: `USER#${userId}`,
            SK: `GOAL#${goalId}`,
            data: goalItem
          }
        }));
      }

      // 3. Create transactions
      for (let i = 0; i < seedTransactions.length; i++) {
        const txId = `tx_seed_${i}_${userId.slice(0, 8)}`;
        const txDate = new Date();
        txDate.setDate(txDate.getDate() - (i + 1) * 2);

        // Pick account ID
        let preferredType = seedTransactions[i].type === "income" ? "bank" : "upi";
        if (seedTransactions[i].channel === "cash") preferredType = "cash";
        const account = accounts.find(a => a.type === preferredType) || accounts[0];

        const txItem = {
          id: txId,
          userId: userId,
          accountId: account.id,
          title: seedTransactions[i].title,
          amount: seedTransactions[i].amount,
          type: seedTransactions[i].type,
          category: seedTransactions[i].category,
          transactionAt: txDate.toISOString(),
          createdAt: now.toISOString(),
          updatedAt: now.toISOString(),
          tags: [seedTransactions[i].type],
          source: seedTransactions[i].source,
          channel: seedTransactions[i].channel,
          isCategoryOverridden: false
        };

        await ddbDocClient.send(new PutCommand({
          TableName: TABLE_NAME,
          Item: {
            PK: `USER#${userId}`,
            SK: `TRANSACTION#${txId}`,
            data: txItem
          }
        }));

        // Link to account's transaction list in memory/db (optional but let's update account list)
        account.transactionIds.push(txId);
      }

      // Re-save accounts with transactionIds
      for (const account of accounts) {
        await ddbDocClient.send(new PutCommand({
          TableName: TABLE_NAME,
          Item: {
            PK: `USER#${userId}`,
            SK: `ACCOUNT#${account.id}`,
            data: account
          }
        }));
      }

      return successResponse({ success: true }, responseHeaders);
    }

    return errorResponse("Route not found", 404, responseHeaders);

  } catch (err) {
    console.error("Handler error:", err);
    return errorResponse(err.message, 500, responseHeaders);
  }
};

function successResponse(body, headers) {
  return {
    statusCode: 200,
    headers,
    body: JSON.stringify(body)
  };
}

function errorResponse(message, statusCode, headers) {
  return {
    statusCode,
    headers,
    body: JSON.stringify({ error: message })
  };
}
