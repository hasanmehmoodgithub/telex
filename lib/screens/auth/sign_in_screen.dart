import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:telex/common/custom_form_button.dart';
import 'package:telex/common/custom_input_field.dart';
import 'package:telex/common/page_header.dart';
import 'package:telex/common/page_heading.dart';
import 'package:telex/common/responsive_widget.dart';
import 'package:telex/screens/auth/sign_up_page.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  //
  final _loginFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SafeArea(
        child: Scaffold(
          backgroundColor: const Color(0xffEEF1F3),
          body: ResponsiveWidget(
            maxWidth: 600.0,
            child: Column(
              children: [
                const PageHeader(height: 0.3,),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20),),
                    ),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _loginFormKey,
                        child: Column(
                          children: [
                            const PageHeading(title: 'Log-in',),
                            CustomInputField(
                               controller:_emailController,
                              labelText: 'Email',
                              hintText: 'Enter Your email id',
                              validator: (textValue) {
                                if (textValue == null || textValue.isEmpty) {
                                  return 'Email is required!';
                                } else if (!emailRegExp.hasMatch(textValue)) {
                                  return 'Please enter a valid email!';
                                }
                                return null;
                              }
                            ),
                            const SizedBox(height: 16,),
                            CustomInputField(
                              controller:_passwordController,
                              labelText: 'Password',
                              hintText: 'Enter Your password',
                              obscureText: true,
                              suffixIcon: true,
                              validator: (textValue) {
                                if(textValue == null || textValue.isEmpty) {
                                  return 'Password is required!';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16,),
                            const SizedBox(height: 20,),
                     
                            _isLoading
                                ? const CircularProgressIndicator():
                            CustomFormButton(innerText: 'Login', onPressed: _handleLoginUser,),
                            const SizedBox(height: 18,),
                            SizedBox(
                              width: size.width * 0.8,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Don\'t have an account ? ', style: TextStyle(fontSize: 13, color: Color(0xff939393), fontWeight: FontWeight.bold),),
                                  GestureDetector(
                                    onTap: () => {

                                      Navigator.push(
                                          context, MaterialPageRoute(builder: (context) => const
                                      SignupScreen()))
                                    },
                                    child: const Text('Sign-up', style: TextStyle(fontSize: 15, color: Color(0xff748288), fontWeight: FontWeight.bold),),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20,),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  void _handleLoginUser()async {
    // login user
    if (_loginFormKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {


       ///1

        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim());

        // On success, navigate to Home Screen
        Navigator.pushReplacementNamed(context, '/home');
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'sigIn Failed')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  // Sign in method

}


final RegExp emailRegExp = RegExp(
    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
);

