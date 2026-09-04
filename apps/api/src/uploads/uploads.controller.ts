import {
  Controller,
  Param,
  Post,
  UploadedFile,
  UseInterceptors,
} from "@nestjs/common";
import {
  ApiBearerAuth,
  ApiBody,
  ApiConsumes,
  ApiOkResponse,
  ApiTags,
} from "@nestjs/swagger";
import { FileInterceptor } from "@nestjs/platform-express";
import { Throttle } from "@nestjs/throttler";

import { CurrentUser } from "../common/auth/auth-user.decorator";
import { AuthenticatedUser } from "../common/auth/authenticated-user";
import { UploadedImageDto } from "./dto/uploaded-image.dto";
import { UploadedImageFile } from "./uploaded-image-file";
import { UploadsService } from "./uploads.service";

const imageUploadBody = {
  schema: {
    type: "object",
    properties: {
      file: {
        type: "string",
        format: "binary",
      },
    },
    required: ["file"],
  },
};

@ApiBearerAuth()
@ApiTags("uploads")
@Controller({ path: "uploads", version: "1" })
export class UploadsController {
  constructor(private readonly uploads: UploadsService) {}

  @Post("groups/:groupId/image")
  @Throttle({ default: { limit: 10, ttl: 60000, blockDuration: 300000 } })
  @UseInterceptors(FileInterceptor("file", { limits: { fileSize: 5 * 1024 * 1024 } }))
  @ApiConsumes("multipart/form-data")
  @ApiBody(imageUploadBody)
  @ApiOkResponse({ type: UploadedImageDto })
  uploadGroupImage(
    @CurrentUser() user: AuthenticatedUser,
    @Param("groupId") groupId: string,
    @UploadedFile() file?: UploadedImageFile,
  ) {
    return this.uploads.uploadGroupImage(user, groupId, file);
  }

  @Post("profile-picture")
  @Throttle({ default: { limit: 10, ttl: 60000, blockDuration: 300000 } })
  @UseInterceptors(FileInterceptor("file", { limits: { fileSize: 5 * 1024 * 1024 } }))
  @ApiConsumes("multipart/form-data")
  @ApiBody(imageUploadBody)
  @ApiOkResponse({ type: UploadedImageDto })
  uploadProfilePicture(
    @CurrentUser() user: AuthenticatedUser,
    @UploadedFile() file?: UploadedImageFile,
  ) {
    return this.uploads.uploadProfilePicture(user, file);
  }
}
