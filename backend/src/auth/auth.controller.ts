import { Body, Controller, Get, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { RegisterVendorDto } from './dto/register-vendor.dto';
import { LoginDto } from './dto/login.dto';
import { Public } from '../common/decorators/public.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtPayload } from './types/jwt-payload';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Public()
  @Post('register-vendor')
  @ApiOperation({ summary: 'Register a vendor account and store' })
  registerVendor(@Body() dto: RegisterVendorDto) {
    return this.auth.registerVendor(dto);
  }

  @Public()
  @Post('login')
  @ApiOperation({ summary: 'Login and receive a JWT' })
  login(@Body() dto: LoginDto) {
    return this.auth.login(dto);
  }

  @Get('me')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Current vendor / admin profile' })
  me(@CurrentUser() user: JwtPayload) {
    return this.auth.me(user.sub);
  }
}
