session_NTSCData:
	.byte 6
	.byte 6

session_Metasprite0_data:

	.byte   48,   0,$21,0
	.byte   40,   0,$22,0
	.byte   24,   0,$53,0
	.byte   32,   0,$33,0

	.byte    8,<- 8,$3e,0
	.byte    8,   0,$3f,0
	.byte    0,   0,$1c,0
	.byte   16,   0,$1e,0
	.byte $80


session_Player_data:

	.byte <- 8,<- 8,$a8,0
	.byte    0,<- 8,$a9,0
	.byte <- 8,   0,$b8,0
	.byte    0,   0,$b9,0
	.byte $80


session_pointers:

	.word session_Metasprite0_data
	.word session_Player_data

