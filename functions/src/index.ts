import * as functions from "firebase-functions";
// Usamos 'require' para máxima compatibilidade no ambiente de Cloud Functions
// eslint-disable-next-line @typescript-eslint/no-var-requires
const {VertexAI} = require("@google-cloud/vertexai");

// Configuração do Projeto
const project = "hooke-loja-pdv-d2e5c";
const location = "us-central1";

// Inicialização dos serviços da Vertex AI
const vertexAI = new VertexAI({project: project, location: location});
const generativeModel = vertexAI.getGenerativeModel({
  model: "gemini-1.5-flash-001", // Usamos um modelo moderno e rápido
});

/**
 * Função chamada pelo Flutter para gerar o resumo de uma venda.
 */
export const generateSummary = functions.https.onCall(async (request) => {
  const prompt = request.data.prompt;

  // Validação de segurança para garantir que o prompt é uma string
  if (typeof prompt !== 'string' || !prompt) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "O pedido tem de incluir um 'prompt' de texto válido.",
    );
  }

  functions.logger.info(`Gerando resumo para prompt de ${prompt.length} caracteres.`);

  try {
    // A forma mais direta e robusta de chamar a API
    const result = await generativeModel.generateContent(prompt);
    const response = result.response;
    const summary = response.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!summary) {
      throw new Error("A resposta da API Gemini veio vazia.");
    }

    functions.logger.info(`Resumo gerado: "${summary}"`);

    // Devolve o resumo para a aplicação Flutter
    return {summary: summary};
  } catch (error) {
    functions.logger.error("Erro detalhado ao chamar a API Gemini:", error);
    throw new functions.https.HttpsError(
      "internal",
      "Ocorreu um erro interno ao contactar a IA.",
      error,
    );
  }
});