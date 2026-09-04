import * as Joi from "joi";

export const envValidationSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid("development", "test", "production")
    .default("development"),
  API_PORT: Joi.number().port().default(3000),
  API_HOST_BIND: Joi.string().default("127.0.0.1"),
  API_PUBLIC_PORT: Joi.number().port().default(3002),
  DATABASE_URL: Joi.string().uri().required(),
  REDIS_URL: Joi.string().uri().required(),
  JWT_ACCESS_SECRET: Joi.string().min(24).required(),
  JWT_REFRESH_SECRET: Joi.string().min(24).required(),
  ACCESS_TOKEN_TTL_SECONDS: Joi.number().integer().positive().default(900),
  REFRESH_TOKEN_TTL_DAYS: Joi.number().integer().positive().default(30),
  CORS_ORIGINS: Joi.string().default("http://localhost:3000"),
  TRUST_PROXY: Joi.boolean().default(true),
  ENABLE_SWAGGER: Joi.boolean().default(false),
  RATE_LIMIT_TTL_MS: Joi.number().integer().positive().default(60000),
  RATE_LIMIT_MAX_REQUESTS: Joi.number().integer().positive().default(120),
  RATE_LIMIT_BLOCK_DURATION_MS: Joi.number()
    .integer()
    .positive()
    .default(60000),
  BILLING_PROVIDER: Joi.string().valid("mock", "sayari").default("sayari"),
  MOCK_BILLING_WEBHOOK_SECRET: Joi.string()
    .min(24)
    .when("BILLING_PROVIDER", {
      is: "mock",
      then: Joi.required(),
      otherwise: Joi.optional(),
    }),
  SAYARI_PAYMENT_BASE_URL: Joi.string().uri().when("BILLING_PROVIDER", {
    is: "sayari",
    then: Joi.required(),
    otherwise: Joi.optional(),
  }),
  SAYARI_PAYMENT_API_KEY: Joi.string().when("BILLING_PROVIDER", {
    is: "sayari",
    then: Joi.required(),
    otherwise: Joi.optional(),
  }),
  SAYARI_PAYMENT_CALLBACK_SECRET: Joi.string()
    .min(24)
    .when("BILLING_PROVIDER", {
      is: "sayari",
      then: Joi.required(),
      otherwise: Joi.optional(),
    }),
  BRIQ_BASE_URL: Joi.string().uri().default("https://karibu.briq.tz"),
  BRIQ_API_KEY: Joi.string().required(),
  BRIQ_SENDER_ID: Joi.string().required(),
  SMTP_HOST: Joi.string().required(),
  SMTP_PORT: Joi.number().port().default(587),
  SMTP_SECURE: Joi.boolean().default(false),
  SMTP_USER: Joi.string().required(),
  SMTP_PASSWORD: Joi.string().required(),
  EMAIL_FROM: Joi.string().default("vikoPlus <no-reply@vikoplus.co.tz>"),
  OBJECT_STORAGE_DRIVER: Joi.string()
    .valid("cloudinary", "local")
    .default("cloudinary"),
  CLOUDINARY_CLOUD_NAME: Joi.string().when("OBJECT_STORAGE_DRIVER", {
    is: "cloudinary",
    then: Joi.required(),
    otherwise: Joi.optional(),
  }),
  CLOUDINARY_API_KEY: Joi.string().when("OBJECT_STORAGE_DRIVER", {
    is: "cloudinary",
    then: Joi.required(),
    otherwise: Joi.optional(),
  }),
  CLOUDINARY_API_SECRET: Joi.string().when("OBJECT_STORAGE_DRIVER", {
    is: "cloudinary",
    then: Joi.required(),
    otherwise: Joi.optional(),
  }),
  DEFAULT_LOCALE: Joi.string().valid("en", "sw").default("en"),
});
