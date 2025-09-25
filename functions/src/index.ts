import * as functions from "firebase-functions";
// eslint-disable-next-line @typescript-eslint/no-var-requires
const {VertexAI} = require("@google-cloud/vertexai");

const project = "hooke-loja-pdv-d2e5c";
const location = "us-central1";

const vertexAI = new VertexAI({project: project, location: location});
const generativeModel = vertexAI.getGenerativeModel({
  model: "gemini-1.5-flash-001",
});

export const generateSummary = functions.https.onCall(async (request) => {
  // O prompt vem do nosso Flutter App
  const saleData = request.data.sale; // Vamos assumir que o Flutter envia os dados da venda

  if (!saleData) {
    throw new functions.https.HttpsError(
      "invalid-argument", "O pedido tem de incluir os dados da venda ('sale')."
    );
  }

  // --- LÓGICA DE GERAÇÃO DO PROMPT (SUA SUGESTÃO APLICADA) ---
  const items = saleData.items || [];
  const itemsDescription = items
    .slice(0, 5) // Pega apenas nos primeiros 5 itens
    .map((item: any) => `- ${item.quantity}x ${item.productName} (${item.variantColor}, Tam: ${item.skuSize})`)
    .join('\n');

  const prompt = `Gere um resumo conciso e amigável, em uma frase, para a seguinte venda realizada por "${saleData.userName}":
${itemsDescription}
${items.length > 5 ? '...e mais itens.' : ''}
Total: R$ ${saleData.totalAmount.toFixed(2)}`;
  // --- FIM DA LÓGICA DO PROMPT ---

  functions.logger.info(`Gerando resumo para o prompt: "${prompt}"`);

  try {
    const result = await generativeModel.generateContent(prompt);
    const response = result.response;
    const summary = response.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!summary) {
      throw new Error("A resposta da API Gemini veio vazia.");
    }

    functions.logger.info(`Resumo gerado: "${summary}"`);
    return {summary: summary};
  } catch (error) {
    functions.logger.error("Erro ao chamar a API Gemini:", error);
    throw new functions.https.HttpsError(
      "internal", "Ocorreu um erro ao gerar o resumo.", error
    );
  }
});