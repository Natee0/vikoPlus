import { ValidationPipe, VersioningType } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { NestFactory } from "@nestjs/core";
import { NestExpressApplication } from "@nestjs/platform-express";
import { DocumentBuilder, SwaggerModule } from "@nestjs/swagger";
import helmet from "helmet";
import { AppModule } from "./app.module";

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  const config = app.get(ConfigService);
  const origins = config
    .getOrThrow<string>("CORS_ORIGINS")
    .split(",")
    .map((origin) => origin.trim())
    .filter(Boolean);

  app.use(helmet());
  app.set("trust proxy", config.getOrThrow<boolean>("TRUST_PROXY"));
  app.enableCors({ origin: origins, credentials: true });
  app.enableVersioning({ type: VersioningType.URI, defaultVersion: "1" });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  if (config.getOrThrow<boolean>("ENABLE_SWAGGER")) {
    const documentConfig = new DocumentBuilder()
      .setTitle("Vikoplus API")
      .setDescription("REST API for Vikoplus group contribution management.")
      .setVersion("0.1.0")
      .addBearerAuth()
      .build();
    SwaggerModule.setup(
      "docs",
      app,
      SwaggerModule.createDocument(app, documentConfig),
    );
  }

  await app.listen(config.getOrThrow<number>("API_PORT"));
}

void bootstrap();
