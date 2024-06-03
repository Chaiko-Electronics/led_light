#define F_CPU 9600000

#include <avr/io.h>
#include <util/delay.h>
#include <avr/sleep.h>
#include <avr/interrupt.h>
#include "math.h"

#define LED1 PB1
#define LED2 PB0
#define ENC1 PB3
#define ENC2 PB4
#define ENCB PB5
#define MAX 250
#define STEPS 16.0


volatile int brightness = 0;
volatile uint8_t a0;
volatile uint8_t c0;

void sleep() {
  set_sleep_mode(SLEEP_MODE_PWR_DOWN);

  cli();
  sleep_enable();
  sleep_bod_disable();
  sei();
  sleep_cpu();
}

void pwm_setup (void)
{
    // Set Timer 0 prescaler to clock/8.
    // At 9.6 MHz this is 1.2 MHz.
    // See ATtiny13 datasheet, Table 11.9.
    TCCR0B |= (1 << CS01);
 
    // Set to 'Fast PWM' mode
    TCCR0A |= (1 << WGM01) | (1 << WGM00);
 
    // Clear OC0B output on compare match, upwards counting.
    TCCR0A |= (1 << COM0B1);
}

void check_encoder() {
	uint8_t a = PINB>>ENC1 & 1;
	uint8_t b = PINB>>ENC2 & 1;
	if (a != a0) {              // A changed
		a0 = a;
		if (b != c0) {
			c0 = b;
			if(a == b) {
		  		brightness++;
			}
			else {
				brightness--;
			}
		}
	}

	if(brightness > STEPS) brightness = STEPS;
	if(brightness <= 0) brightness = 0;
}

int main() {
	DDRB |= _BV(LED1) | _BV(LED2);
	PORTB |= _BV(ENC1) | _BV(ENC2) | _BV(ENCB);
	PORTB &= ~_BV(LED1) &  ~_BV(LED2);

	pwm_setup();
	PCMSK = (1 << ENC1); // set pin change mask
	GIMSK = (1 << PCIE); // enable pin change interrupt
	sleep();
	OCR0B = 0;

 while (1) {

 	//int b1 = ((brightness - 8) < 0) ? 0 : brightness - 7;
 	//int b2 = (brightness < 7) ? brightness : 7;

	if(brightness == 0) {
		sleep();
	}
	else {
		double val = brightness / STEPS;

		TCNT0=0;
		OCR0A = pow(exp(val*2.0 - 2.0), 2.0) * MAX;
		OCR0B = pow(exp(val*2.0 - 2.0), 2.0) * MAX;
	}
 }

 return 0;
}

ISR(PCINT0_vect) {
	cli();
	check_encoder();
	sei();
}