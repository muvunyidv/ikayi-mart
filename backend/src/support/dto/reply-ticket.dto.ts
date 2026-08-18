import { IsString, IsUUID, MaxLength, MinLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class ReplyTicketDto {
  @ApiProperty()
  @IsUUID()
  ticketId!: string;

  @ApiProperty({ example: 'Replacement cable dispatched with rider.' })
  @IsString()
  @MinLength(4)
  @MaxLength(2000)
  resolution!: string;
}
