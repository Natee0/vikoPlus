import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  ServiceUnavailableException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { AuditAction, GroupMemberStatus, GroupRole } from "@prisma/client";
import { createHash } from "crypto";

import { AuthenticatedUser } from "../common/auth/authenticated-user";
import { PrismaService } from "../prisma/prisma.service";
import { UploadedImageDto } from "./dto/uploaded-image.dto";
import { UploadedImageFile } from "./uploaded-image-file";

const maxImageBytes = 5 * 1024 * 1024;
const imageMimeTypes = new Set(["image/jpeg", "image/png", "image/webp"]);

type CloudinaryResponse = {
  public_id?: unknown;
  secure_url?: unknown;
  bytes?: unknown;
};

@Injectable()
export class UploadsService {
  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
  ) {}

  async uploadGroupImage(
    user: AuthenticatedUser,
    groupId: string,
    file: UploadedImageFile | undefined,
  ): Promise<UploadedImageDto & { groupId: string }> {
    await this.requireGroupAdmin(user, groupId);
    const asset = await this.uploadImage(file, "group-images", `group-${groupId}`);
    await this.prisma.group.update({
      where: { id: groupId },
      data: { logoObjectKey: asset.objectKey },
    });
    await this.prisma.auditLog.create({
      data: {
        actorUserId: user.id,
        groupId,
        action: AuditAction.GROUP_UPDATED,
        entityType: "Group",
        entityId: groupId,
        newValue: { logoObjectKey: asset.objectKey },
      },
    });
    return { groupId, ...asset };
  }

  async uploadProfilePicture(
    user: AuthenticatedUser,
    file: UploadedImageFile | undefined,
  ): Promise<UploadedImageDto & { userId: string }> {
    const asset = await this.uploadImage(
      file,
      "profile-pictures",
      `user-${user.id}`,
    );
    await this.prisma.user.update({
      where: { id: user.id },
      data: { profilePictureObjectKey: asset.objectKey },
    });
    return { userId: user.id, ...asset };
  }

  private async uploadImage(
    file: UploadedImageFile | undefined,
    folder: "group-images" | "profile-pictures",
    publicIdPrefix: string,
  ): Promise<UploadedImageDto> {
    this.validateFile(file);

    if (this.config.get<string>("OBJECT_STORAGE_DRIVER") !== "cloudinary") {
      throw new ServiceUnavailableException(
        "Cloudinary storage is not configured for this environment.",
      );
    }

    const cloudName = this.config.getOrThrow<string>("CLOUDINARY_CLOUD_NAME");
    const apiKey = this.config.getOrThrow<string>("CLOUDINARY_API_KEY");
    const apiSecret = this.config.getOrThrow<string>("CLOUDINARY_API_SECRET");
    const timestamp = Math.floor(Date.now() / 1000).toString();
    const cloudinaryFolder = `vikoplus/${folder}`;
    const publicId = `${publicIdPrefix}-${Date.now()}`;
    const signature = this.sign({
      folder: cloudinaryFolder,
      public_id: publicId,
      timestamp,
    }, apiSecret);

    const form = new FormData();
    form.append("file", `data:${file.mimetype};base64,${file.buffer.toString("base64")}`);
    form.append("folder", cloudinaryFolder);
    form.append("public_id", publicId);
    form.append("timestamp", timestamp);
    form.append("api_key", apiKey);
    form.append("signature", signature);

    const response = await fetch(
      `https://api.cloudinary.com/v1_1/${encodeURIComponent(cloudName)}/image/upload`,
      { method: "POST", body: form },
    );
    const body = (await response.json().catch(() => ({}))) as CloudinaryResponse;

    if (!response.ok) {
      throw new ServiceUnavailableException("Image upload failed.");
    }

    if (typeof body.public_id !== "string" || typeof body.secure_url !== "string") {
      throw new ServiceUnavailableException("Image upload response was invalid.");
    }

    return {
      objectKey: body.public_id,
      url: body.secure_url,
      folder: cloudinaryFolder,
      bytes: typeof body.bytes === "number" ? body.bytes : file.size,
    };
  }

  private validateFile(
    file: UploadedImageFile | undefined,
  ): asserts file is UploadedImageFile {
    if (!file) {
      throw new BadRequestException("Image file is required.");
    }
    if (!imageMimeTypes.has(file.mimetype)) {
      throw new BadRequestException("Only JPG, PNG, and WebP images are allowed.");
    }
    if (file.size > maxImageBytes) {
      throw new BadRequestException("Image must be 5MB or smaller.");
    }
  }

  private sign(params: Record<string, string>, secret: string): string {
    const payload = Object.entries(params)
      .sort(([left], [right]) => left.localeCompare(right))
      .map(([key, value]) => `${key}=${value}`)
      .join("&");
    return createHash("sha1").update(`${payload}${secret}`).digest("hex");
  }

  private async requireGroupAdmin(
    user: AuthenticatedUser,
    groupId: string,
  ): Promise<void> {
    const membership = await this.prisma.groupMember.findFirst({
      where: {
        groupId,
        userId: user.id,
        status: GroupMemberStatus.ACTIVE,
        role: GroupRole.GROUP_ADMIN,
      },
      select: { id: true },
    });
    if (!membership) {
      throw new ForbiddenException("Group image access denied.");
    }
  }
}
