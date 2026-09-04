import { ApiProperty } from "@nestjs/swagger";

export class UploadedImageDto {
  @ApiProperty()
  objectKey!: string;

  @ApiProperty()
  url!: string;

  @ApiProperty()
  folder!: string;

  @ApiProperty()
  bytes!: number;
}
