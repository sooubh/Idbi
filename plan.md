# Plan: Convert `summer-hacks-v2` into an AI Wealth Advisor App

## 1. Objective

Transform the current finance app into a **hackathon-ready AI-powered Digital Wealth Advisor** for a bank mobile application.

The new product should focus on:

- **Friendly avatar-based advisory**
- **Gemini-powered AI guidance**
- **Personalized wealth recommendations**
- **Spending behavior analysis**
- **Savings and investment nudges**
- **AWS backend migration** in a simple, hackathon-appropriate way

The user experience should feel like a **friendly financial buddy**, not a cold banking dashboard.

---

## 2. Product Positioning

### New concept
A digital wealth assistant that helps users understand:

- Where their money is going
- How healthy their finances are
- Whether they can invest more
- What savings goals they should prioritize
- What action they should take next

### Personality
The avatar should feel:

- Friendly
- Supportive
- Simple to understand
- Encouraging
- Non-judgmental
- Human-like

### Tone examples
Good:
- “Nice progress this month.”
- “You are doing better than last month.”
- “Here is a simple next step.”

Avoid:
- Overly formal banking language
- Scolding tone
- Too much jargon
- Long explanations on the main screen

---

## 3. What to Reuse from the Existing Repo

The repo already contains the right finance foundation:

- Authentication
- Accounts
- Transactions
- Savings goals
- Split expenses
- Dashboard
- Insights
- Notifications
- Assistant layer
- Voice assistant
- Firebase rules and Cloud Functions

These existing areas are useful because the wealth advisor needs financial behavior data to generate advice.

### Reuse and rename
- `assistant` → `wealth_advisor`
- `insights` → `wealth_insights`
- `dashboard` → `wealth_dashboard`
- `savings` → `goals`
- `transactions` → `spending intelligence`

---

## 4. Final Feature Set

### Core features
1. **3D Avatar Advisor**
2. **Gemini-powered advisory chat**
3. **Financial health score**
4. **Spending pattern analysis**
5. **Personalized recommendations**
6. **Savings goal guidance**
7. **Investment readiness check**
8. **Voice interaction support**
9. **Backend migration to AWS**
10. **Bank-style dashboard with friendly AI guidance**

### Hackathon-friendly story
The app should demonstrate that it converts raw financial data into simple, personalized wealth advice through a friendly avatar.

---

## 5. Priority Order

The best build order is:

1. **Avatar experience**
2. **Gemini integration**
3. **Wealth intelligence logic**
4. **AWS backend migration**
5. **Data model migration**
6. **Polish and demo flow**

Do not start with backend migration first. Judges will see the avatar and AI first, not the database.

---

## 6. Phase 1: Avatar Experience First

This is the highest priority.

## Goal
When the app opens, the avatar should instantly make the app feel alive.

### Avatar screen requirements
- A dedicated wealth advisor landing screen
- A visible 3D avatar in the center
- Friendly greeting on app open
- Idle animation
- Thinking animation while loading AI
- Speaking animation when responding
- Quick action buttons
- Chat entry point
- Voice input and voice output later

### Avatar states
Use a small state machine:

- `idle`
- `thinking`
- `speaking`
- `happy`
- `warning`
- `alert`

### Avatar behavior examples
- `idle`: default screen
- `thinking`: while Gemini generates a response
- `speaking`: while TTS audio plays
- `happy`: when the user is financially healthy
- `warning`: when spending is high
- `alert`: when cash flow or goal progress is weak

### Visual goal
The avatar should feel like a friendly assistant, not a corporate bank employee.

---

## 7. Avatar Implementation Strategy

For hackathon speed, keep it lightweight.

### Recommended approach
Use a **3D model or avatar package** rather than building a full custom metaverse-style system.

### Practical choices
- Ready Player Me style avatar
- A `.glb` / `.gltf` avatar
- A Flutter 3D viewer package
- Simple animations over complex rigging

### What matters most
- The avatar is visible immediately
- It changes state based on AI response
- It speaks through text-to-speech
- It feels interactive and alive

### Do not overbuild
Avoid spending too much time on:
- advanced facial tracking
- full body motion capture
- custom 3D environment rendering
- complicated avatar customization systems

For hackathon, **clean and responsive is better than overly complex**.

---

## 8. Phase 2: Gemini AI Integration

This is the intelligence layer behind the avatar.

## Goal
Gemini should transform financial data into short, actionable advice.

### Important rule
Do **not** call Gemini directly from Flutter with the API key.

Use backend mediation.

### Safe flow
```text
Flutter App
   ↓
Backend API / Lambda / Function
   ↓
Gemini API
   ↓
Structured JSON response
   ↓
Avatar + UI
```

### Why backend mediation matters
- Keeps the API key secure
- Allows prompt control
- Makes it easier to add rules
- Helps with response formatting
- Works better for hackathon demo stability

---

## 9. Gemini Response Design

Gemini should return structured JSON, not only plain text.

### Suggested response format
```json
{
  "summary": "Your spending is stable this month.",
  "mood": "happy",
  "healthScore": 78,
  "spokenLine": "You are doing well. Your savings rate improved by 6 percent.",
  "recommendations": [
    "Increase monthly savings by ₹2,000",
    "Reduce dining out by 15 percent",
    "Move surplus cash into a goal"
  ],
  "actions": [
    "See spending breakdown",
    "Create savings goal",
    "Ask for investment advice"
  ]
}
```

### Why JSON is important
It allows the app to:
- update the avatar mood
- show the health score
- render recommendation cards
- display action buttons
- trigger voice output

---

## 10. Phase 3: Wealth Intelligence Layer

This layer converts existing app data into wealth signals.

### Data already available in the repo
- Accounts
- Transactions
- Savings goals
- Insights
- Notifications
- Dashboard data
- Assistant system

### Convert to wealth features
- Accounts → financial holdings
- Transactions → spending behavior
- Savings goals → financial goals
- Insights → wealth recommendations
- Notifications → proactive nudges

---

## 11. Wealth Features to Build

### A. Financial Health Score
A simple score between 0 and 100.

### Inputs
- Savings rate
- Monthly expenses
- Goal progress
- Cash surplus
- Spending trend

### Example
- 85–100: Excellent
- 70–84: Good
- 50–69: Needs attention
- Below 50: Risk area

### Output
- Score number
- Friendly explanation
- Avatar mood
- Next recommendation

---

### B. Spending Coach
Analyze category-wise spending.

### Examples
- food
- travel
- shopping
- bills
- entertainment
- miscellaneous

### Output example
- “Dining out increased by 18 percent this month.”
- “Reducing this by ₹1,500 can improve your savings rate.”

---

### C. Savings Guidance
Show the user:
- current savings pace
- whether they are on track
- how much more they need to save
- what monthly action is needed

### Example
- “You need to save ₹2,500 more per month to hit your goal.”

---

### D. Investment Readiness
This is important for the hackathon problem statement.

### Estimate
- conservative
- moderate
- aggressive

### Based on
- surplus
- savings consistency
- spending volatility
- goal completion
- cash reserve

### Output example
- “You appear ready for a moderate investment plan.”
- “Keep an emergency reserve before increasing risk.”

---

## 12. Avatar + AI Interaction Design

The avatar should not just sit there.

### Chat flow
1. User asks a question
2. App sends financial context to Gemini
3. Gemini returns JSON
4. Avatar changes mood
5. Avatar speaks summary
6. UI shows cards and actions
7. User taps an action or follows up

### Example questions
- “How am I doing financially?”
- “Can I invest this month?”
- “Where am I overspending?”
- “What should I improve?”
- “Am I on track for my goal?”

### Example avatar replies
- “You are in a good position this month.”
- “Your spending is stable, but dining is a bit high.”
- “You can probably invest a small amount after keeping emergency savings safe.”

---

## 13. Voice Experience

Voice makes the app feel more premium and demo-ready.

### Two parts
1. **Speech-to-text** for user questions
2. **Text-to-speech** for avatar responses

### Flow
- User taps mic
- Speaks question
- Gemini processes it
- Avatar speaks the answer

### For hackathon
Voice can be added after the avatar and chat work.

---

## 14. Backend Migration Priority

The backend should be migrated only after the avatar and Gemini flow are working in the demo version.

### Migration priority order
1. Authentication
2. AI backend
3. Database
4. Notifications
5. Optional storage support

---

## 15. AWS Backend Plan

For the hackathon, keep the AWS architecture simple.

### Recommended AWS services
- **Amazon Cognito** for authentication
- **AWS Lambda** for backend logic
- **Amazon DynamoDB** for finance data
- Optional: **Amazon Bedrock** if using an AWS-native AI story

### Skip for hackathon
- ECS
- EKS
- Step Functions
- RDS
- SNS
- EventBridge

Those are not needed for the MVP.

---

## 16. AWS Migration Phases

### Phase 1: Authentication
Replace Firebase Auth with Cognito.

### Why first
- Lowest risk
- Easy to explain
- Foundational for all user data

### Output
- Google sign-in
- Email-based login if needed
- JWT tokens
- User identity stored in Cognito

---

### Phase 2: Gemini Proxy Backend
Move Gemini calls to Lambda.

### Why
- Protect Gemini API keys
- Control prompt format
- Return structured data safely

### Lambda functions
- `chatAdvisor`
- `generateHealthScore`
- `generateRecommendations`
- `generateInvestmentReadiness`
- `summarizeMonthlySpending`

---

### Phase 3: Database Migration
Move Firestore data to DynamoDB.

### Suggested tables
- Users
- Transactions
- Goals
- Insights
- Notifications
- Accounts

### Example partitioning
- `PK = USER#123`
- `SK = TXN#001`
- `SK = GOAL#001`
- `SK = INSIGHT#001`

---

### Phase 4: Optional Notifications
Only add notifications if needed for demo polish.

Examples:
- low savings alert
- spending warning
- goal reminder
- monthly advisory summary

---

## 17. Suggested DynamoDB Data Shape

### Users table
Stores:
- user id
- name
- avatar preference
- risk profile
- health score

### Accounts table
Stores:
- account type
- balance
- active status
- linked user

### Transactions table
Stores:
- amount
- category
- timestamp
- transaction type

### Goals table
Stores:
- target amount
- saved amount
- deadline
- status

### Insights table
Stores:
- AI summary
- recommendation text
- severity
- created date

---

## 18. How to Reframe Existing Repo Modules

### Authentication
Keep but move to AWS later.

### Dashboard
Turn into wealth dashboard:
- net worth
- spending rate
- savings score
- goal progress
- advisor summary

### Assistant
Rename to wealth advisor chat.

### Savings
Rename to financial goals.

### Insights
Turn into advice cards.

### Notifications
Turn into proactive financial nudges.

---

## 19. Screen-by-Screen Build Plan

### Screen 1: Home / Avatar Screen
Contains:
- 3D avatar
- greeting
- current health score
- chat input
- quick prompts

### Screen 2: Chat Screen
Contains:
- conversational UI
- Gemini responses
- speaking state
- suggested actions

### Screen 3: Wealth Dashboard
Contains:
- score cards
- spending trends
- savings progress
- recommendation cards

### Screen 4: Goals Screen
Contains:
- goal list
- progress bars
- target amount
- monthly required savings

### Screen 5: Insights Screen
Contains:
- AI recommendations
- warnings
- user-friendly summaries

---

## 20. Demo Flow for Hackathon

The demo should feel polished and clear.

### Flow
1. User opens the app
2. Friendly avatar appears
3. Avatar greets the user
4. App loads spending summary
5. Avatar explains the financial health score
6. User asks if they can invest
7. Gemini returns a personalized recommendation
8. Avatar speaks the answer
9. Dashboard updates with charts and recommendations

### What judges should feel
- The app is useful
- The avatar is the differentiator
- The AI is personalized
- The backend is modern
- The product feels bank-ready

---

## 21. Prompt Design for Gemini

### System prompt goals
Tell Gemini:
- It is a friendly wealth assistant
- It should keep answers simple
- It should sound encouraging
- It should avoid overclaiming
- It should not sound like a generic chatbot
- It should return structured JSON
- It should use user spending data responsibly

### Good response style
- short
- practical
- personal
- action-oriented

### Bad response style
- long paragraphs
- technical finance jargon
- vague advice
- overly generic suggestions

---

## 22. Risk and Safety Considerations

Since this is a wealth app, the AI should be careful.

### Avoid
- pretending to guarantee returns
- giving overly specific market predictions
- using unsafe financial language
- making the user feel judged
- exposing secrets in client code

### Prefer
- cautious guidance
- clear uncertainty
- simple advice
- user-friendly explanation
- safe fallback replies

---

## 23. Development Milestone Plan

### Milestone 1
Avatar screen works with idle animation

### Milestone 2
Gemini API returns structured JSON

### Milestone 3
Avatar speaks AI response

### Milestone 4
Financial health score is generated

### Milestone 5
Savings and spending intelligence is shown

### Milestone 6
AWS backend migration begins

### Milestone 7
Cognito + Lambda + DynamoDB integration completes

### Milestone 8
Demo-ready polish and presentation

---

## 24. Recommended Build Order Summary

### Highest priority
1. Avatar UI
2. Avatar animation
3. Gemini advisory backend
4. Voice response
5. Wealth insight output

### Second priority
6. Spending analytics
7. Financial health score
8. Savings guidance
9. Investment readiness

### Backend priority
10. Cognito
11. Lambda
12. DynamoDB
13. Optional notifications

---

## 25. Final Deliverable Definition

The final app should feel like:

- a bank-grade advisor assistant
- friendly and approachable
- powered by AI
- able to analyze financial behavior
- capable of giving personalized guidance
- visually centered around a 3D avatar
- ready for a hackathon demo

---

## 26. Success Criteria

The project is successful if:

- the avatar becomes the first thing users notice
- Gemini gives useful personalized advice
- the app can explain spending and savings behavior
- the backend is secure and simple
- the demo clearly matches the hackathon problem statement
- the product feels like a digital wealth advisor, not just a finance tracker

