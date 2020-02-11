
/*
This class user with validator in TextFormField
Provides Email, Password, and Name validation
*/
class Validator {

  //Validate if the user provides a valid Name
  //No number if not valid return a message
  static String validateName(String value) {
    Pattern pattern = r"^[a-zA-Z]+(([',. -][a-zA-Z ])?[a-zA-Z]*)*$";
    RegExp regex = new RegExp(pattern);
    if (!regex.hasMatch(value))
      return 'Please enter a name.';
    else if(!regex.hasMatch(value) || value.length > 70)
      return 'Please enter a valid name';
    else
      return null;
  }

  //Validate if the user provides a valid Email
  //Need and @ and . if not valid return a message
  static String validateEmail(String value) {
    Pattern pattern = r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+';
    RegExp regex = new RegExp(pattern);
    if (!regex.hasMatch(value))
      return 'Please enter a valid email address.';
    else
      return null;
  }

  //Validate if the user provides a valid Password
  //Need (6 characters long) if not valid return a message
  static String validatePassword(String value) {
    Pattern pattern = r'^.{6,}$';
    RegExp regex = new RegExp(pattern);
    if (!regex.hasMatch(value))
      return 'Password must be at least 6 characters.';
    else
      return null;
  }

//Validate if the user's response is null
    static String responseValidator(String value) {
      Pattern pattern = r'^(?=\s*\S).*$';
      RegExp regex = new RegExp(pattern);
      if (!regex.hasMatch(value))
        return 'Please enter a response.';
      else
        return null;
    }
}