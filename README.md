SARD script language
====================

It is a script language not programming language.

The idea behind it, it is not use any of reserved word only signs, only objects there is no "void", "function" or "procedure"

When i finish it it will be clear than i can explain it.

It is: File parsed, result executed in interpreter (possibly multiple times)

####Compare####

#####Like pascal#####

  It is case insensitive
  Declareing after the name
  Assigning ":=", compare "=", object child "."
  Dot as Identifier separator "."
  Not equal operator "<>"
  Return value not end the execute of block

    foo:{
      bar: integer;
      i: integer = 5; //Declare and Assign
      method1:{
        :=i * bar //return value
      }
    }

    foo.bar := 10;

#####Like C#####

  Block { }, no more begin end
  comments //single line and /* multiline */
  Not "!"  or "|"


####Reference####

  https://www.d.umn.edu/~rmaclin/cs5641/Notes/L16_Interpreters.pdf

###Examples###

#####Done:#####

    /*
      This examples are worked, and this comment will ignored, not compiled or parsed as we say.
    */
    x := 10 +5 - (5 * 5); //Single Line comment

    x := x + 10; //Using same variable, until now local variable implemented
    x := {    //Block it any where
          y := 0;
          := y + 5; //this is a result return of the block
      }; //do not forget to add ; here
    {* This a block comment, compiled, useful for documentation, or regenrate the code *};
    := x; //Return result to the main object

First init of the variable define the type

    s:='Foo';
    s:=s+' Bar';
    :=s; //It will retrun 'Foo Bar';

    i := 10;
    i := i + 5.5;
    //variable i now have 15 not 15.5

    i := 10.0;
    i := i + 5.5;
    //variable i now have 15.5

Next f is a function or let us say it is an object we can run it.

    f:{
        x := 10;
        z: {
          x:=5;
          := x + 5;
        };
        := x + z;

      };

    :=f + 10;

Declare function/object with parameters

    foo:(p1, p2) {
      := p1 * p2;
    };

    x := 10;

    := x + foo(5, 5);



Declare a variable type, type now not working but parsed

    x:integer;

    x:integer=10;

You can use = as assignment

    x=10;


#####TODO:#####

    x:=#0; // Boolean values, true and false words are just global variables.
    x:=#1;
    x:=#fc0f1c; //Color const and operator mix the colors not just add it
    x:=0xffec;  //hex integer number like but the style of print it as hex we need to override ToString
    x:="foo"\13"bar"; //escape char outside the string
    x:="I said:"\""As he said";

    //include external file to compile it

    `lib/foo.sard`; //need a good trick, but it must take a relative path to the current file

    /*
        Preprocessor, it will run in external addon/command.... and return string into it
        similar to <?foo ?> in xml
    */
    {?foo
    ?}

    //Run child object
    f.b;

    //there is no 'if' so we need this, still have no idea how i can do it by scanner
    (x=10)?{ true bock }:{ false block }
    maybe statment not blocks
    condition statment ? true statment : false statment;  // and you can put a block inside ur statment to be like example above.

    // -With-
    object.{     <-not sure
    };

Still working on it.

###Compile###

FreePascal 2.6.4

I need contributors to port it to Java or C, it is easy to port becuase i still not use any special features of FPC.

###License###

The SARD script is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT)