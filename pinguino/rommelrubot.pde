//Write Distance Sensor value to serial port. 
//Distance sensor connected on AN0 (Pinguino pin 13, PIC pin 2)
/*
						 _  _
				gnd		|_||_|		vcc (5V)
			dist sensor	|_||_|
			dist sensor 2	|_||_|
						|_||_|
						|_||_|
						|_||_|
						|_||_|
						|_||_|
						|_||_|
						|_||_|
						|_||_|
						|_||_|
						|_||_|
						|_||_|
						|_||_|
				to RX	|_||_|
				to TX 	|_||_|
				
B2 = pin35 = pinguino pin 2 			-> naar driver 4 (2 op connector)
B3 = pin36 = pinguino pin 3			-> naar driver 1 (1 op connector)
C1 = pin16 = pinguino pin 11 (PWM)	-> naar driver 2 (3 op connector)
C2 = pin17 = pinguino pin 12 (PWM)	-> naar driver 3 (4 op connector)


*/

#define PIC18F4550

 #include <string.h>
 #include <stdlib.h>

 
int i;
int caractere;
unsigned int j;
unsigned int dist1;
unsigned int dist2;

int cnt = 0;

int incomingByte = 'C';	// for incoming serial data
char stringbuffer[20];	//buffer for reading one line of the serial input
int bufferpos = 0;
int motor1 = 0;
int motor2 = 0;

//servo
uchar servoAngle 			= 90;	//[0,180]


int testval = 0;

//servo
void setServoAngle(uchar pin,uchar angle) {	//set new servo value (called from external code)
	uchar position;					//convert angle to a position between 1 and 250 (http://pinguino.koocotte.org/index.php/Servo.write)
	position = 1 + angle * ( (250-1) / 180 ) ;	//SERVOMIN + angle * ( (SERVOMAX - SERVOMIN) / 180 );
	servo.write( pin , position );
}

void setup() {
  //INTCON2bits.RBPU = 0;	// Enable pullups on portb

  //LEDs
  for (i=21; i <= 28; i++) {
	pinMode(i,OUTPUT);
	digitalWrite(i,HIGH);
  }

TRISBbits.TRISB0 = 1;	// portb buttons = inputs
TRISBbits.TRISB1 = 0;
TRISBbits.TRISB4 = 1;
TRISBbits.TRISB5 = 1;
TRISBbits.TRISB6 = 1;
TRISBbits.TRISB7 = 1;
TRISBbits.TRISB2 = 0;	//portb pwm = outputs
TRISBbits.TRISB3 = 0;

  //Motor pins  
  for (i=2; i <= 3; i++) {
	pinMode(i,OUTPUT);
	digitalWrite(i,LOW);
  }
  for (i=11; i <= 12; i++) {
	pinMode(i,OUTPUT);
	digitalWrite(i,LOW);
  }  
   
    Serial.begin(57600);
    servo.attach(2);			//initialize servo on pin2 (PIC pin 35, RB2)
    setServoAngle(2,90);	//set the servo in the mid-position (90°)

}

void setDrive(int val) {
	if (val == 'F') {	//FORWARD
		digitalWrite(3,HIGH);
		digitalWrite(11,LOW);
	} else if (val == 'B') { //BACKWARD
		digitalWrite(3,LOW);
		digitalWrite(11,HIGH);
	} else {	//STOP
		digitalWrite(3,LOW);
		digitalWrite(11,LOW);
	}
}

void setSteer(int val) {
	if (val == 'R') {	//RIGHT
		//digitalWrite(2,LOW);
		//digitalWrite(12,HIGH);
		setServoAngle( 2 , 180);
	} else if (val == 'L') { //LEFT
		//digitalWrite(2,HIGH);
		//digitalWrite(12,LOW);
		setServoAngle( 2 , 0);
	} else {	//STOP
		//digitalWrite(2,LOW);
		//digitalWrite(12,LOW);
		setServoAngle( 2 , 90);
	}
}





void loop() {
	delay(3);
	
	// send data only when you receive data:
	if (Serial.available()) {
		// read the incoming byte:		
		stringbuffer[bufferpos] = Serial.read();
		if (stringbuffer[bufferpos] == '\n') {	//end of the line, interpret the command
			stringbuffer[bufferpos+1] = '\0';	//write end-of-string char
			//stringbuffer[bufferpos+2] = '\0';
			//Serial.print("I got ");
			//j = 0;
			//while (stringbuffer[j] != '\0') {
				//Serial.print(stringbuffer[j],BYTE);

			//	j++;
			//}

			//Serial.print('\0');
			if (strcmp(stringbuffer,"PING\n") == 0) {
				Serial.print("PONG\r\n");	//reply with PONG
				  //LEDs
				  for (i=21; i <= 25; i++) {
					pinMode(i,OUTPUT);
					digitalWrite(i,LOW);
				  }
				
			} else if (strcmp(stringbuffer,"GET_SENSORS\n") == 0) {
				dist1=analogRead(13);
				dist2 = analogRead(14);
				
				testval = TMR1H*255 + TMR1L;
				Serial.print("A,");
				Serial.print(dist1,DEC);
				Serial.print(",");
				Serial.print(dist2,DEC);
				Serial.print(";\r\n");
			} else if (stringbuffer[0] == 'D' && stringbuffer[1] == ',') {
				//parse D,val1,val2\n

				strtok(stringbuffer,",\n");	//points to D
				motor1 = atoi(strtok(NULL, ",\n"));		//points to val1
				motor2 = atoi(strtok(NULL, ",\n"));		//points to val2
				
				/*
				if (motor1 == 0) {
					setSteer('A');
				} else if (motor1 == -1) {
					setSteer('L');
				} else if (motor1 == 1) {
					setSteer('R');
				}
				*/
				setServoAngle( 2 , motor1);
				
				if (motor2 == 0) {
					setDrive('A');
				} else if (motor2 == -1) {
					setDrive('B');
				} else if (motor2 == 1) {
					setDrive('F');
				}
			} else {
				Serial.print("HANK\r\n");	//reply with PONG
			}
			bufferpos = 0;
		} else {
			bufferpos++;
		}
		//Serial.print("I got..");
		//Serial.print(incomingByte);
		
		  //LEDs
		//  for (i=21; i <= 28; i++) {
		//	pinMode(i,OUTPUT);
		//	digitalWrite(i,LOW);
		//  }
	


		cnt = 0;
	}

}

