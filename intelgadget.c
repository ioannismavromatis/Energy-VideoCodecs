/* Intel Power Gadget API implementation.
Uses the Intel Power Gadget APIs to sample the processor frequency 
and estimated processor package power in real-time.
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <signal.h>
#ifdef WIN32
#include <windows.h>
#elif _POSIX_C_SOURCE >= 199309L
#include <time.h>   // for nanosleep
#else
#include <unistd.h> // for usleep
#endif

#include <IntelPowerGadget/Headers/EnergyLib.h>

bool printall = false;
char input[] = "printall";

void sleep_ms(int milliseconds) { // cross-platform sleep function
	#ifdef WIN32
		Sleep(milliseconds);
	#elif _POSIX_C_SOURCE >= 199309L
		struct timespec ts;
		ts.tv_sec = milliseconds / 1000;
		ts.tv_nsec = (milliseconds % 1000) * 1000000;
		nanosleep(&ts, NULL);
	#else
		if (milliseconds >= 1000)
		sleep(milliseconds / 1000);
		usleep((milliseconds % 1000) * 1000);
	#endif
}

void sig_handler(int signo) {
	if (signo == SIGTERM) {
		printf("received SIGTERM\n");
		sleep(1);
		StopLog(); // causes a sample to be read

		// Exit gracefully
		exit(0);
	}
}

int stringEndsWith(const char * str, const char * suffix)
{
  int str_len = strlen(str);
  int suffix_len = strlen(suffix);

  return 
    (str_len >= suffix_len) &&
    (0 == strcmp(str + (str_len-suffix_len), suffix));
}

void checkArguments(char* argv[]) {
	// printf("argv[1]: %s\n", argv[1]);
	
	if ( argv[1] == NULL) {
		printf("At least one argument is required. This argument is the log file name.\n");
		printf("For example, call Intel Power Gadget APIs tool like as follows: \n");
		printf("./intelgadget mysamplename.csv {printall} \n");
		exit(EXIT_FAILURE);
	}
	else {
		if (!stringEndsWith(argv[1], ".csv")) {
			printf("Wrong filename provided, i.e:, %s\n", argv[1]);
			printf("The name should be in the form: XXXXX.csv \n");
			exit(EXIT_FAILURE);
		}
	}

	if ( argv[2] == NULL) {
		printall = false;
	}
	else {
		int result = strcmp(input, argv[2]);
		// printf("strcmp(str1, str2) = %d\n", result);

		if (result == 0) {
			printall = true;
		}
		else {
			printf("The second argument is wrong, i.e., %s\n", argv[2]);
			printf("You should use either pass 'printall' or do not pass any arguments \n");
			exit(EXIT_FAILURE);
		}
	}

}

void printOnTerminal (int numMsrs) {
	int cpuData;
	GetCpuUtilization(0,&cpuData);
	
	for (int j = 0; j < numMsrs; j++) {
		int funcID;
		char szName[1024];
		GetMsrFunc(j, &funcID);
		GetMsrName(j, szName);
		
		int nData;
		
		double data[3];
		GetPowerData(0, j, data, &nData);

				// Frequency
		if (funcID == MSR_FUNC_FREQ) {
			printf("%s = %4.0f", szName, data[0]);
		}
		
		// CPU Utilisation
		else if (funcID == MSR_FUNC_FREQ) {
			printf("%s = %4.0f", szName, data[0]);
		}

		// Power
		else if (funcID == MSR_FUNC_POWER) {
			printf(", %s Power (W) = %3.2f", szName, data[0]);
			printf(", %s Energy(J) = %3.2f", szName, data[1]);
			printf(", %s Energy(mWh)=%3.2f", szName, data[2]);
		}
		
		// Temperature
		else if (funcID == MSR_FUNC_TEMP) {
			printf(", %s Temp (C) = %3.0f", szName, data[0]);
		}

		else {
			printf(", CPU Utilisation (%%) = %3.0d", cpuData);
		}

	}
	printf("\n");

}

int main(int argc, char* argv[]) {
	if (signal(SIGTERM, sig_handler) == SIG_ERR) {
        printf("\ncan't catch SIGTERM\n");
	}

	checkArguments(argv);

	IntelEnergyLibInitialize();
	StartLog(argv[1]); // causes a sample to be read
	
	int numMsrs = 0;
	GetNumMsrs(&numMsrs);
	
	while(1) {
		
		sleep_ms(100);
		ReadSample();
		
		if (printall == true) {
			printOnTerminal(numMsrs);
		}
		
	}
	
	return 0;
}

