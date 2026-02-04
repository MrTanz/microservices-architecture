const axios = require('axios');
const { SSMClient, GetParameterCommand } = require("@aws-sdk/client-ssm");

const ssmClient = new SSMClient();

async function getParameter(parameterName) {
    try {
        const command = new GetParameterCommand({
            Name: parameterName,
            WithDecryption: true
        });

        const response = await ssmClient.send(command);
        return response.Parameter.Value;
    } catch (err) {
        console.error(`Error in Get Parameter from SSM: ${parameterName}`, err);
        throw err;
    }
}

exports.handler = async (event) => {
    console.log("[START SQS HANDLER] event = ", JSON.stringify(event));

    const { AUTH_SERVICE_URL, INTERNAL_API_KEY_NAME } = process.env;
    const body = JSON.parse(event.Records[0].body);
    const username = body.username;

    try {
        const internalApiKey = await getParameter(INTERNAL_API_KEY_NAME);

        console.log(`[SUCCESS] Internal Api Key Retrieved!`);

        const response = await axios.delete(`${AUTH_SERVICE_URL}/auth/${username}/credentials`, {
            headers: {
                "Content-Type": "application/json",
                "internal-api-key": internalApiKey
            }
        });

        console.log(`[SUCCESS] Credentials deleted for user = ${username}`);

        return {
            statusCode: 200,
            body: JSON.stringify({
                message: response.data,
            }),
        };
    } catch (error) {
        console.error(`Error deleting credentials for user = ${username}, error =`, error.message);

        return {
            statusCode: 500,
            body: JSON.stringify({
                error: `Failed to delete credentials for user ${username}`,
                details: error.message,
            }),
        };
    }
};
