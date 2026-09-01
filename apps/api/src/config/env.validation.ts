import * as Joi from "joi";

export const envValidationSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid("development", "test", "production")
    .default("development"),
  API_PORT: Joi.number().port().default(3000),
  DATABASE_URL: Joi.string().uri().required(),
  REDIS_URL: Joi.string().uri().required(),
  JWT_ACCESS_SECRET: Joi.string().min(24).required(),
  JWT_REFRESH_SECRET: Joi.string().min(24).required(),
  ACCESS_TOKEN_TTL_SECONDS: Joi.number().integer().positive().default(900),
  REFRESH_TOKEN_TTL_DAYS: Joi.number().integer().positive().default(30),
  CORS_ORIGINS: Joi.string().default("http://localhost:3000"),
  BILLING_PROVIDER: Joi.string().valid("mock").default("mock"),
  MOCK_BILLING_WEBHOOK_SECRET: Joi.string().min(24).required(),
  OBJECT_STORAGE_DRIVER: Joi.string().valid("local").default("local"),
  DEFAULT_LOCALE: Joi.string().valid("en", "sw").default("en"),
});
