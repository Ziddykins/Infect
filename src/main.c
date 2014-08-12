#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <ncurses.h>
#include <unistd.h>

#define X 100
#define Y 50
#define NORM	"\x1B[0m"
#define RED		"\x1B[31m"
#define GREEN 	"\x1B[32m"
#define BLUE 	"\x1B[34m"
#define MAG		"\x1B[35m"
#define CYAN	"\x1B[36m"

typedef enum _directions {NORTH, WEST, SOUTH, EAST} Directions;
typedef enum _deltas {NONE, N=-1, W=-1, S=1, E=1} Deltas;
typedef enum _characters {EMPTY,DEAD, INF, DOC, CIT, SOL} Characters;
typedef enum _actions {NOTHING, DIE, DOCTORED, INFECTED, CITIZENED, SOLDIERED, REVIVE, CLEAN} Actions;

typedef struct _infected {
	const float nothing;
	const float kill;
	const float die;
	const float doctored;
	const float convert;
	const float citizened;
	const float soldiered;
	const float trade;
} Infected;

typedef struct _doctor {
	const float nothing;
	const float doctored;
} Doctor;

typedef struct _citizen {
	const float nothing;
	const float doctored;
	const float infected;
} Citizen;

typedef struct _soldier {
	const float nothing;
	const float action;
} Soldier;

typedef struct _probabilities {
	Infected *infectedProb;
	Doctor *doctorProb;
	Citizen *citizenProb;
	Soldier *soldierProb;
} Probabilities;

typedef struct _board {
	Characters character;
	Actions action;
	int direction;
	void *probabilities;
} Board;

typedef void (*action)(Board*, Board*);

void generateCoord(Board board[][X], const int count, Characters type, Probabilities probabilities);
void initialise(Board board[][X], Probabilities probabilities);
void defaultBoard(Board board[][X], Probabilities probabilities);
void displayBoard(Board board[][X], int days);
void getActions(Board board[][X], Probabilities probabilities);
Board * getDelta(Board board[][X], int y, int x);
void getMoves(Board board[][X]);
void processActions(Board board[][X], Probabilities probabilities);
void checkTarget(Board board[][X], int y, int x, action getAction);
void getActionInf(Board *infected, Board *target);
void getActionDoc(Board *doctor, Board *target);
void getActionCit(Board *soldier, Board *target);
void getActionSol(Board *soldier, Board *target);
int checkOutBounds(Board board[][X], Directions move, int y, int x);


int main (int argc, char **argv) 
{
	int days = 0;
	srand(time(NULL));
	initscr();
	noecho();
	start_color();

	init_pair(1, COLOR_RED, COLOR_BLACK);
	init_pair(2, COLOR_GREEN, COLOR_BLACK);
	init_pair(3, COLOR_BLUE, COLOR_BLACK);
	init_pair(4, COLOR_MAGENTA, COLOR_BLACK);

	Infected infectedActions = {0.75f, 0.25f, 0.25f, 0.05f, 0.25f, 0.05f, 0.05f, 0.10f};
	Doctor doctorActions = {0.95f, 0.05f};
	Citizen citizenActions = {0.98f, 0.01f, 0.01f};
	Soldier soldierActions = {0.75f, 0.25f};
	Probabilities probabilities = {&infectedActions, &doctorActions, &citizenActions, &soldierActions};

	Board board[Y][X] = {{0}};	

	initialise(board, probabilities);
	do {
		if (!(days%5)) {
			displayBoard(board, days);
			refresh();
			sleep(1);
		}
		//printf("\n\n");
		getActions(board, probabilities);
		processActions(board, probabilities);
		getMoves(board);
		++days;
	} while (days < 1000);	
	
	endwin();
}

void initialise(Board board[][X], Probabilities probabilities)
{
	const int countS = 1, countI = 3, countD = 10;

	defaultBoard(board, probabilities);	
	generateCoord(board, countS, SOL, probabilities);
	generateCoord(board, countI, INF, probabilities);
	generateCoord(board, countD, DOC, probabilities);
}

void processActions(Board board[][X], Probabilities probabilities)
{
	for (size_t i = 0; i < Y; i++) {
		for (size_t j = 0; j < X; j++) {
			switch (board[i][j].action) {
				case NOTHING:
					break;
				case DIE:
					board[i][j].character = DEAD;
					board[i][j].probabilities = NULL;
					break;
				
				case INFECTED:
					board[i][j].character = INF;
					board[i][j].probabilities = probabilities.infectedProb;
					break;

				case DOCTORED:
					board[i][j].character = DOC;
					board[i][j].probabilities = probabilities.doctorProb;
					break;

				case SOLDIERED:
					board[i][j].character = SOL;
					board[i][j].probabilities = probabilities.soldierProb;
					break;

				case CITIZENED:
					board[i][j].character = CIT;
					board[i][j].probabilities = probabilities.citizenProb;
					break;

				case REVIVE:
					board[i][j].character = CIT;
					board[i][j].probabilities = probabilities.citizenProb;

				case CLEAN:
					board[i][j].character = EMPTY;
					board[i][j].probabilities = NULL;
			}

			board[i][j].action = NOTHING;
			board[i][j].direction = NONE;
		}
	}
}

void getMoves(Board board[][X])
{
	for (size_t i = 0; i < Y; i++) {
		for (size_t j = 0; j < X; j++) {
			switch (board[i][j].character) {
				case INF:
				case DOC:
				case CIT:
				case SOL:
					board[i][j].direction = rand()%4;
					if (!checkOutBounds(board, board[i][j].direction, i, j)) {
						Board *target = getDelta(board, i, j);
						if (target->character == EMPTY) {
							target->character = board[i][j].character;
							board[i][j].character = EMPTY;
						}
					}
					break;
				case DEAD:
				case EMPTY:
					break;
			}
		}
	}
}

void getActions(Board board[][X], Probabilities probabilities) 
{
	for (size_t i = 0; i < Y; i++) {
		for (size_t j = 0; j < X; j++) {
			board[i][j].direction = rand()%4; 
			switch (board[i][j].character) {
				case DEAD: //fallthrough
				case EMPTY:
					break;
				case INF:
					if (rand()%100 >= 75 && !checkOutBounds(board, board[i][j].direction, i, j)) { 
						checkTarget(board, i, j, getActionInf);
					}
					break;
				case DOC:
					if (!checkOutBounds(board, board[i][j].direction, i, j)) {
						checkTarget(board, i, j, getActionDoc);	
					}
					break;
				case CIT:
					if (rand()%100 >= 98 && !checkOutBounds(board, board[i][j].direction, i, j)) {
						checkTarget(board, i, j, getActionCit);
					}
					break;
				case SOL:
					if (rand()%100 >= 75 && !checkOutBounds(board, board[i][j].direction, i, j)) {
						checkTarget(board, i, j, getActionSol);
					}
					break;
			}
		}
	}
}

Board * getDelta(Board board[][X], int y, int x)
{
	Board *attacker = &board[y][x];
	Board *target = malloc(sizeof(Board));	
	Deltas delta = attacker->direction == NORTH ? N : attacker->direction == SOUTH ? S : attacker->direction == WEST ? W : E;

	if (attacker->direction == NORTH || attacker->direction == SOUTH) {
		target = &board[y + delta][x];
	} else {
		target = &board[y][x + delta];
	}

	return target;

} 

void checkTarget(Board board[][X], int y, int x, action getAction)
{
	Board *target;
	
	target = getDelta(board, y, x);

	getAction(&board[y][x], target);
}

void getActionInf(Board *infected,  Board *target)
{
	if (target->character == CIT) {
		target->action = INFECTED;
	} else if (target->character == DOC) {
		int prob = rand()%100;
	
		if (prob < 5) {
			infected->action = DOCTORED;
		} else if (prob >=5 && prob < 10) {
			infected->action = CITIZENED;
		} else if (prob >=10 && prob < 15) {
			infected->action = SOLDIERED;
		} else if (prob >= 15 && prob < 25) {
			infected->action = DIE;
			target->action = DIE;
		} else if (prob >= 25 && prob < 50) {
			target->action = INFECTED;
		} else if (prob >= 50 && prob < 75) {
			target->action = DIE;
		} else {
			infected->action = DIE;
		}
	}		
}

void getActionDoc(Board *doctor, Board *target)
{
	int prob = rand()%100;
	if (target->character == CIT || target->character == INF) {
		if (prob < 7) {
			target->action = DOCTORED;
		}
	} else if (target->character == DEAD) {
		if (prob == 10) {
			target->action = REVIVE;
		}
	}
}

void getActionCit(Board *citizen, Board *target)
{
	int prob = rand()%100;
	if (prob == 10) {
		citizen->action = DOCTORED;
	} else if (prob == 23) {
		citizen->action = INFECTED;
	}
}

void getActionSol(Board *soldier, Board *target)
{
	int prob = rand()%100;
	if (target->character == DOC) {
		if (prob == 11) {
			target->action = DIE;
		}
	} else if (target->character == INF) {
		target->action = DIE;
	} else if (target->character == DEAD) {
		target->action = CLEAN;
	} else if (target->character == CIT) {
		if (prob >=80) {
			target->action = SOLDIERED;
		}
	}
}

int checkOutBounds(Board board[][X], Directions move, int y, int x)
{
	if (move == NORTH) {
		//board[y][x].direction = N;		
		return (y + N >= 0 ? 0 : 1);
	} else if (move == SOUTH) {
		//board[y][x].direction = S;
		return(y + S < Y ? 0 : 1);
	} else if (move == WEST) {
		//board[y][x].direction = W;
		return(x + W >= 0 ? 0 : 1);
	} else {
		//board[y][x].direction = E;
		return(x + E < X ? 0 : 1);
	}
}

void displayBoard(Board board[][X], int days) 
{
	size_t i;
	
	for (i = 0; i < Y; i++) {
		for (size_t j = 0; j < X; j++) {
			switch (board[i][j].character) {
				case SOL:
					//printf("%sS", MAG);
					attron(COLOR_PAIR(4));
					mvprintw(i, j, "S");
					attroff(COLOR_PAIR(4));
					break;
				
				case INF:
					//printf("%sI", RED);
					attron(COLOR_PAIR(1));
					mvprintw(i, j, "I");
					attroff(COLOR_PAIR(1));
					break;

				case DOC:
					//printf("%sD", BLUE);
					attron(COLOR_PAIR(3));
					mvprintw(i, j, "D");
					attroff(COLOR_PAIR(3));
					break;

				case CIT:
					//printf("%sO", GREEN);
					attron(COLOR_PAIR(2));
					mvprintw(i, j, "O");
					attroff(COLOR_PAIR(2));		
					break;

				case DEAD:
					mvprintw(i, j, "X");
					break;
				
				default:
					//printf("%sX", NORM);
					mvprintw(i, j, " ");
					break;
			}
		}
		//printf("\n");
	}
	mvprintw(i, 0, "Day %d", days);
}	

void defaultBoard(Board board[][X], Probabilities probabilities)
{
	for (size_t i = 0; i < Y; i++) {
		for (size_t j = 0; j < X; j++) {
			board[i][j].character = CIT;
			board[i][j].action = NOTHING;
			board[i][j].direction = NONE;
			board[i][j].probabilities = probabilities.citizenProb;
		}
	} 
}

void generateCoord(Board board[][X], const int count, Characters type, Probabilities probabilities)
{
	int x = 0, y = 0;

	for (size_t i = 0; i < count; i++) {
		do {
			x = rand()%X;
			y = rand()%Y;
		} while(board[y][x].character != CIT);
		
		board[y][x].character = type;
		
		if (type == DOC) {
			board[y][x].probabilities = probabilities.doctorProb;
		} else if (type == INF) {
			board[y][x].probabilities = probabilities.infectedProb;
		} else {		
			board[y][x].probabilities = probabilities.soldierProb;
		}
	} 
}
	
