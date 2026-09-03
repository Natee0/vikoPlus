import { Injectable, UnauthorizedException } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { createHmac, randomUUID, timingSafeEqual } from "crypto";

type TokenType = "access" | "refresh";

type TokenPayload = {
  sub: string;
  jti: string;
  typ: TokenType;
  iat: number;
  exp: number;
};

@Injectable()
export class TokenService {
  constructor(private readonly config: ConfigService) {}

  signAccessToken(userId: string): { token: string; tokenId: string } {
    const tokenId = randomUUID();
    return {
      tokenId,
      token: this.sign({
        sub: userId,
        jti: tokenId,
        typ: "access",
        iat: this.now(),
        exp:
          this.now() +
          this.config.getOrThrow<number>("ACCESS_TOKEN_TTL_SECONDS"),
      }),
    };
  }

  signRefreshToken(userId: string): {
    token: string;
    tokenId: string;
    expiresAt: Date;
  } {
    const tokenId = randomUUID();
    const expiresAt = new Date(
      Date.now() +
        this.config.getOrThrow<number>("REFRESH_TOKEN_TTL_DAYS") *
          24 *
          60 *
          60_000,
    );
    return {
      tokenId,
      expiresAt,
      token: this.sign({
        sub: userId,
        jti: tokenId,
        typ: "refresh",
        iat: this.now(),
        exp: Math.floor(expiresAt.getTime() / 1000),
      }),
    };
  }

  verifyAccessToken(token: string): TokenPayload {
    const payload = this.verify(token, "access");
    return payload;
  }

  verifyRefreshToken(token: string): TokenPayload {
    return this.verify(token, "refresh");
  }

  private sign(payload: TokenPayload): string {
    const header = { alg: "HS256", typ: "JWT" };
    const encodedHeader = this.base64Url(JSON.stringify(header));
    const encodedPayload = this.base64Url(JSON.stringify(payload));
    const signature = this.signature(
      `${encodedHeader}.${encodedPayload}`,
      this.secret(payload.typ),
    );
    return `${encodedHeader}.${encodedPayload}.${signature}`;
  }

  private verify(token: string, expectedType: TokenType): TokenPayload {
    const parts = token.split(".");
    if (parts.length !== 3) {
      throw new UnauthorizedException("Invalid bearer token.");
    }
    const [encodedHeader, encodedPayload, signature] = parts as [
      string,
      string,
      string,
    ];
    const payload = JSON.parse(
      Buffer.from(encodedPayload, "base64url").toString("utf8"),
    ) as TokenPayload;
    if (payload.typ !== expectedType || payload.exp <= this.now()) {
      throw new UnauthorizedException("Bearer token expired or invalid.");
    }
    const expected = this.signature(
      `${encodedHeader}.${encodedPayload}`,
      this.secret(payload.typ),
    );
    if (!this.safeCompare(signature, expected)) {
      throw new UnauthorizedException("Invalid bearer token signature.");
    }
    return payload;
  }

  private signature(value: string, secret: string): string {
    return createHmac("sha256", secret).update(value).digest("base64url");
  }

  private secret(type: TokenType): string {
    return this.config.getOrThrow<string>(
      type === "access" ? "JWT_ACCESS_SECRET" : "JWT_REFRESH_SECRET",
    );
  }

  private base64Url(value: string): string {
    return Buffer.from(value, "utf8").toString("base64url");
  }

  private safeCompare(actual: string, expected: string): boolean {
    const actualBuffer = Buffer.from(actual);
    const expectedBuffer = Buffer.from(expected);
    if (actualBuffer.length !== expectedBuffer.length) return false;
    return timingSafeEqual(actualBuffer, expectedBuffer);
  }

  private now(): number {
    return Math.floor(Date.now() / 1000);
  }
}
