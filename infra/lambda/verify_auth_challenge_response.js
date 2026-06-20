exports.handler = async (event) => {
  console.log("VerifyAuthChallengeResponse received event:", JSON.stringify(event));

  const expectedAnswer = event.request.privateChallengeParameters.answer;
  if (event.request.challengeAnswer === expectedAnswer) {
    event.response.answerCorrect = true;
  } else {
    event.response.answerCorrect = false;
  }

  console.log("VerifyAuthChallengeResponse response:", JSON.stringify(event));
  return event;
};
