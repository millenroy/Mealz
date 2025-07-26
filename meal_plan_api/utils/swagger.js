import swaggerJSDoc from "swagger-jsdoc";
import swaggerUi from "swagger-ui-express";
const options = {
 definition: {
 openapi: "3.0.0",
 info: {
 title: "Meal Plan API Documentation",
 version: "1.0.0",
 description: "API Documentation for my Node.js project",
 },
 servers: [
 {
 url: "http://localhost:3010", // Update with your server URL
 },
 ],
 },
 apis: ["./routes/*.js"], // Path to API route files
};
const swaggerSpec = swaggerJSDoc(options);
const setupSwagger = (app) => {
 app.use("/api-docs", swaggerUi.serve,
swaggerUi.setup(swaggerSpec));
};
export default setupSwagger;