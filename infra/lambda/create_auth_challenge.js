const { SESClient, SendEmailCommand } = require("@aws-sdk/client-ses");
const ses = new SESClient({ region: process.env.AWS_REGION || "ap-south-1" });

exports.handler = async (event) => {
  console.log("CreateAuthChallenge received event:", JSON.stringify(event));

  let secretLoginCode;
  if (!event.request.session || event.request.session.length === 0) {
    // Generate a 6-digit verification code
    secretLoginCode = Math.floor(100000 + Math.random() * 900000).toString();
    const email = event.request.userAttributes.email;

    try {
      await ses.send(new SendEmailCommand({
        Destination: { ToAddresses: [email] },
        Message: {
          Body: {
            Text: { Data: `Your Wealth Advisor login code is: ${secretLoginCode}` }
          },
          Subject: { Data: "Your Wealth Advisor Login Code" }
        },
        Source: process.env.SES_FROM_EMAIL || email
      }));
      console.log(`Sent login code ${secretLoginCode} to ${email}`);
    } catch (err) {
      console.error("SES email sending failed (normal for sandbox accounts):", err);
      // Log code to CloudWatch logs so it can be retrieved for local/demo verification
      console.log(`[ALERT] Passwordless Login Verification Code for ${email} is: ${secretLoginCode}`);
    }
  } else {
    // If user requests again or retry challenge, carry over previous challenge metadata code
    const previousChallenge = event.request.session.slice(-1)[0];
    secretLoginCode = previousChallenge.challengeMetadata.split(":")[1];
  }

  // Answer is verified against challengeAnswer parameter in VerifyAuthChallengeResponse
  event.response.privateChallengeParameters = {
    answer: secretLoginCode
  };

  event.response.challengeMetadata = `CODE:${secretLoginCode}`;
  
  console.log("CreateAuthChallenge response:", JSON.stringify(event));
  return event;
};
