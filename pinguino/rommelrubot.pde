/*
This code runs on the Pinguino Microcontroller. It requires the Pinguino bootloader 
to be installed on your device, see http://www.hackinglab.org/ for details on the 
Pinguino project.

This code will set up a connection to the serial port and communicate via a simple
protocol to send sensor values and receive motor values. Hardware overview:

* a servo motor as steering device (ackerman drive)
* a simple DC motor as driving motor
* some distance sensors
* a BlueSMIRF Bluetooth modem to send the serial data via Bluetooth to the connecting device (e.g., laptop or Android Phone)
* a Dwengo board is used as Pinguino (see http://www.dwengo.org/products/dwengo-starters-kit for more info on Dwengo)

								_  _
				gnd			|_||_|		vcc (5V)
			dist sensor		|_||_|
			dist sensor 2	|_||_|
								|_||_|
								|_||_|		
								|_||_|		
								|_||_|		
								|_||_|
								|_||_|
servo2 = ping_20, PIC_10|_||_|
								|_||_|
								|_||_|
								|_||_|
								|_||_|
								|_||_|
				to RX			|_||_|
				to TX 		|_||_|
				
B2 = PIC pin35 = pinguino pin 2 			-> naar driver 4 (2 op connector)
B3 = PIC pin36 = pinguino pin 3			-> naar driver 1 (1 op connector)
C1 = PIC pin16 = pinguino pin 11 (PWM)	-> naar driver 2 (3 op connector)
C2 = PIC pin17 = pinguino pin 12 (PWM)	-> naar driver 3 (4 op connector)

2010 - Karel Braeckman - http://kr3l.wordpress.com/tag/rommelrubot/
*/

#define PIC18F4550
#include <string.h>
#include <stdlib.h>

 
int i;
unsigned int dist1;
unsigned int dist2;

char stringbuffer[20];	//buffer for reading one line of the serial input
int bufferpos = 0;
int motor1 = 0;
int motor2 = 0;


//servo
void setServoAngle(uchar pin,uchar angle) {	//set new servo value (called from external code)
	uchar position;					//convert angle to a position between 1 and 250 (http://pinguino.koocotte.org/index.php/Servo.write)
	position = 1 + angle * ( (250-1) / 180 ) ;	//SERVOMIN + angle * ( (SERVOMAX - SERVOMIN) / 180 );
	servo.write( pin , position );
}

void setup() {
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
	
	//second servo for rotating the distance sensor
	pinMode(20,OUTPUT);
	servo.attach(20);			//initialize servo on pin2 (PIC pin 35, RB2)
	setServoAngle(20,90);	//set the servo in the mid-position (90°)
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
		setServoAngle( 2 , 180);
	} else if (val == 'L') { //LEFT
		setServoAngle( 2 , 0);
	} else {	//STOP
		setServoAngle( 2 , 90);
	}
}

void loop() {
	delay(3);
	
	//if (servo.read(20) > 240) {
	//	servo.setMinimumPulse(20);
	//} else {
		servo.setMaximumPulse(20);
	//}
	
	// send data only when you receive data:
	if (Serial.available()) {
		// read the incoming byte:		
		stringbuffer[bufferpos] = Serial.read();
		if (stringbuffer[bufferpos] == '\n') {	//end of the line, interpret the command
			stringbuffer[bufferpos+1] = '\0';	//write end-of-string char

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
	}
}