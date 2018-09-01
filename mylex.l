%{
#include <iostream>
#include <vector>
#include <string>
#include <fstream>
#include <sstream>
#include <stack>
#include <climits>

#define epsilon_state 1
#define null '^'
#define epsilon '$' 

struct Properties{
	bool _is_dfa_nfa;					//nfs(0) or dfa(1)
	int _sCount;						//state count
	int _fCount;						//final state count
	int _aCount;						//alphabet count
};

std::fstream file("specification.txt");
int* _states = NULL; 
int* _final = NULL;
char* _alphabet = NULL;
int** _DTransition_Table = NULL;
int** _nfa_state_size = NULL;
int*** _NTransition_Table = NULL;
Properties* properties = NULL;
int* _hash = NULL;


Properties* _Cmd_Input(int argc, char* argv[]){
	Properties* properties = (struct Properties*)malloc(sizeof(struct Properties));
	for(int i=0; i<argc; i++){
		properties->_is_dfa_nfa = atoi(argv[1]);
		properties->_sCount = atoi(argv[2]);
		properties->_fCount = atoi(argv[3]);
		properties->_aCount = atoi(argv[4]);
	}
	return properties;
}

void _zeroHash(){
	for(int i=0; i< properties->_sCount; i++)
		_hash[i] = 0;
}

void _Hash_Initialize(Properties* properties){
	_hash = new int[properties->_sCount];
	_zeroHash();
}

int** _Dfa_TransiTable(Properties* properties){			//generate transition table based on is  dfa
		int** _Transition_Table = new int*[properties->_sCount];
		for(int i=0; i<properties->_sCount; i++)
			_Transition_Table[i] = new int[properties->_aCount];
		return _Transition_Table;

}

int*** _Nfa_TransiTable(Properties* properties){		//generate transition table based on is nfa
		int*** _Transition_Table = new int**[properties->_sCount];
		for(int i=0; i<properties->_sCount; i++)
			_Transition_Table[i] = new int*[properties->_aCount+ epsilon_state];

		return _Transition_Table;
}

int* _States_Reader(Properties* properties){			//read states from file
	int* _states = new int[properties->_sCount];
	for(int i=0; i<properties->_sCount; i++){
		char _temp[1000];
		file >> _temp;	
		_states[i] = atoi(_temp);
	}
	return _states;
}

int* _Final_Reader(Properties* properties){			//read final states from file
	int* _final = new int[properties->_fCount];
	for(int i=0; i<properties->_fCount; i++){
		char _temp[1000];
		file >> _temp;	
		_final[i] = atoi(_temp);
	}
	return _final;
}

char* _Alphabet_Reader(Properties* properties){			//read alphabets from file
	char* _alphabet = NULL;
	if(properties->_is_dfa_nfa)
		_alphabet = new char[properties->_aCount];
	else
		_alphabet = new char[properties->_aCount+1];
	char _temp;
	for(int i=0; i<properties->_aCount; i++){
		file >> _temp;	
		_alphabet[i] = _temp;
	}
	if(!properties->_is_dfa_nfa)
		_alphabet[properties->_aCount] = '$';
	return _alphabet;
}

void _Table_filler(int** Transition_table, Properties* properties){		//fill dfa transition table
	for(int i=0; i< properties->_sCount; i++){
		for(int j=0; j< properties->_aCount + 1; j++){
			char _temp[1000];
			file >> _temp;
			Transition_table[i][j] = atoi(_temp);
		}
	}
}

void _Table_filler(int*** Transition_table, Properties* properties){
	int _comma_sep_States;
	_nfa_state_size = new int*[properties->_sCount];
	for(int i=0; i<properties->_sCount; i++)
		_nfa_state_size[i] = new int[properties->_aCount + epsilon_state];
	for(int i=0; i<properties->_sCount; i++){
		for(int j=0; j<properties->_aCount + epsilon_state; j++){
			std::string temp ;
			file >> temp;
			_comma_sep_States = temp.length()-(int)(temp.length()/2);
			_nfa_state_size[i][j] = _comma_sep_States;
			Transition_table[i][j] = new int[_comma_sep_States];		
			for(int k=0; k<temp.length(); k++){
				if(temp[k] != ','){
					if(temp[k] == null)
						Transition_table[i][j][k - (int)k/2] = INT_MAX; 
					else
						Transition_table[i][j][k - (int)k/2] = temp[k] - 48; 
				}
			}
		}
	}
}

void _isMatched(int** Transition_table, Properties* properties, int* _final, char* _input){
	int pointer = 0;
	int i=0, j=0, input_length = strlen(_input);
	while(pointer != input_length){
		j = _input[pointer++] - 97; std::cout<<i;
		if(pointer != input_length)
			i = Transition_table[i][j];	
	}
	for(int ii = 0; ii<(properties->_fCount); ii++){
		if(_final[i] == Transition_table[i][j]){
			std::cout<<"MATCHED"<<std::endl;
			return;
		}
	}
	std::cout<<"ERROR"<<std::endl;
}

void _isMatched(int*** Transition_table, Properties* properties, int* _final, char* _input){
	std::stack <int> _stack1, _stack2;
	int pointer = 0, i=0, j=0, input_length = strlen(_input);			
	int epsilon_state_pos = properties->_aCount + epsilon_state ;
	while(pointer != input_length){
		_stack1.push(i);
		_hash[i] = 1;
		j = _input[pointer] - 97;
		i = _stack1.top();
		for(int ii=0; ii< _nfa_state_size[i][epsilon_state_pos-1]; ii++){
			if(Transition_table[i][epsilon_state_pos-1][ii] == INT_MAX){
				continue;
			}
			if(_hash[Transition_table[i][epsilon_state_pos-1][ii]] == 0){
				_stack1.push(Transition_table[i][epsilon_state_pos-1][ii]);	
				_stack2.push(Transition_table[i][epsilon_state_pos-1][ii]);
				_hash[Transition_table[i][epsilon_state_pos-1][ii]] = 1;
				while(!_stack2.empty()){
					if(Transition_table[_stack2.top()][epsilon_state_pos-1][0] == INT_MAX){
						_stack2.pop();
						continue;
					}

					for(int jj=0; jj< _nfa_state_size[_stack2.top()][epsilon_state_pos-1]; jj++){
						if(_hash[Transition_table[_stack2.top()][epsilon_state_pos-1][jj]] == 0){
							_stack1.push(Transition_table[_stack2.top()][epsilon_state_pos-1][jj]);
							_stack2.push(Transition_table[_stack2.top()][epsilon_state_pos-1][jj]);
							_hash[Transition_table[_stack1.top()][epsilon_state_pos-1][jj]] = 1;
							_stack2.pop();
						}
					}
				}				
			}

		}
		_zeroHash();
		while(!_stack1.empty()){
			i = _stack1.top();
			for(int ii=0; ii< _nfa_state_size[i][j]; ii++){
				if(Transition_table[_stack1.top()][j][ii] == INT_MAX){
					break;
				}
				if(_hash[Transition_table[i][j][ii]] == 0){
					_stack2.push(Transition_table[i][j][ii]);	
					_hash[Transition_table[i][j][ii]] = 1;
				}

			}
			_stack1.pop();
		}
		pointer++;
		_stack1 = _stack2;
		while(!_stack2.empty())
			_stack2.pop();
		_zeroHash();
	}

	while(!_stack1.empty()){
		for(int ii = 0; ii<(properties->_fCount); ii++){
			if(_final[ii] == _stack1.top()){
				std::cout<<"MATCHED"<<std::endl;
				return;
			}
		}
		_stack1.pop();
	}
	std::cout<<"ERROR"<<std::endl;
}
%}

%%
[a-z]+ {if(properties->_is_dfa_nfa) _isMatched(_DTransition_Table, properties, _final, yytext);else  _isMatched(_NTransition_Table, properties, _final, yytext);}
%%



int main(int argc, char* argv[]){
	properties = _Cmd_Input(argc, argv);
	if(properties->_is_dfa_nfa)
		_DTransition_Table = _Dfa_TransiTable(properties);
	else
		_NTransition_Table = _Nfa_TransiTable(properties);

	_states = _States_Reader(properties);
	_final = _Final_Reader(properties);
	_alphabet = _Alphabet_Reader(properties);
	 _Hash_Initialize(properties);

	if(properties->_is_dfa_nfa)
		_Table_filler(_DTransition_Table, properties);
	else
		_Table_filler(_NTransition_Table, properties);
	
	/*for(int i=0; i<properties->_sCount; i++){
		for(int j=0; j<properties->_aCount + epsilon_state; j++){
			for(int k=0; k<_nfa_state_size[i][j]; k++){
				std::cout<<_NTransition_Table[i][j][k]; 
			}
			std::cout<<" ";
		}	
		std::cout<<std::endl;
	}*/
	yylex();
	
}
