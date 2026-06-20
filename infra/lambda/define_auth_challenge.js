exports.handler = async (event) => {
  console.log("DefineAuthChallenge received event:", JSON.stringify(event));

  if (event.request.session && event.request.session.find(attempt => attempt.challengeName !== 'CUSTOM_CHALLENGE')) {
    // Only CUSTOM_CHALLENGE is accepted
    event.response.issueTokens = false;
    event.response.failAuthentication = true;
  } else if (event.request.session && event.request.session.length >= 3 && event.request.session.slice(-1)[0].challengeResult === false) {
    // Fail after 3 incorrect attempts
    event.response.issueTokens = false;
    event.response.failAuthentication = true;
  } else if (event.request.session && event.request.session.length > 0 && event.request.session.slice(-1)[0].challengeResult === true) {
    // Correct OTP code provided
    event.response.issueTokens = true;
    event.response.failAuthentication = false;
  } else {
    // Present custom challenge to verify OTP
    event.response.issueTokens = false;
    event.response.failAuthentication = false;
    event.response.challengeName = 'CUSTOM_CHALLENGE';
  }

  console.log("DefineAuthChallenge response:", JSON.stringify(event));
  return event;
};
