import { registerDecorator, ValidationOptions } from 'class-validator';
import { isValidRwandaPhone } from '../utils/rwanda-phone';

export function IsRwandaPhone(validationOptions?: ValidationOptions) {
  return (object: object, propertyName: string) => {
    registerDecorator({
      name: 'isRwandaPhone',
      target: object.constructor,
      propertyName,
      options: validationOptions,
      validator: {
        validate(value: unknown) {
          return typeof value === 'string' && isValidRwandaPhone(value);
        },
        defaultMessage() {
          return 'Enter a valid Rwanda phone number (+250 7XX XXX XXX or 07XX XXX XXX)';
        },
      },
    });
  };
}
