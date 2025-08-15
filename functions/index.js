const functions = require('firebase-functions');
const {SpeechClient} = require('@google-cloud/speech');
const speechClient = new SpeechClient();

// Transcribe audio file stored in Cloud Storage
exports.transcribeAudio = functions.storage.object().onFinalize(async (object) => {
  const gcsUri = `gs://${object.bucket}/${object.name}`;
  const config = {
    encoding: 'LINEAR16',
    sampleRateHertz: 16000,
    languageCode: 'en-US',
    enableAutomaticPunctuation: true,
    model: 'latest_long',
  };
  const audio = {uri: gcsUri};
  const request = {config, audio};
  const [operation] = await speechClient.longRunningRecognize(request);
  const [response] = await operation.promise();
  const transcription = response.results.map(r => r.alternatives[0].transcript).join(' ');
  console.log(`Transcription: ${transcription}`);
  return null;
});

// Categorise text using Vertex AI (placeholder implementation)
exports.categorizeText = functions.https.onCall(async (data, context) => {
  const text = data.text || '';
  const categories = ['lyric idea', 'to-do', 'shopping', 'reminder', 'journal', 'random', 'work', 'personal', 'inspiration'];
  // Simple heuristic: pick random category as placeholder
  const category = categories[Math.floor(Math.random() * categories.length)];
  return {category};
});