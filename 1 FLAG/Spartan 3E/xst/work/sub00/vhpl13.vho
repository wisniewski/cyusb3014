      H  �        T��H         �         :   slave_fifo_arch  � �        H  2�  �  q  Y  A  :�  Bi  ]�  y  �q  ��  �!  ��  �1 q 0� @Q S� [� cy kI s �� z� ~� �� �� �� �q �Y �� �� �Q �! ܑ �1 � �� � q A 6i aa �Y �� �	 �� ҩ ��  � (� 0i Wy ~� �Y �) �� �� �� �a x� �y Oa � �) �� �y  � +� ^� �9 �Q  Z   @  .�  #)  >�  FQ  a�  }  �Y  ��  �	  ީ  � Y 4� D9 W� _� ga o1 w �� �A �� �i �9 �	 �y � �� �� � Y ) :Q eI �A �� �� �� ֑ �� $� ,� 4Q [a �q �A � �� �� �� �I |q �a SI � � �� �9 �a � /� b� �! �i        �� � $! V� �i �� �� �� �a � �� T� � 	i 	?1 	�� 
1a 
`A 
�� i� �� �	 uQ ��  �       �  �     �     -   
idle_state  #)      �     -   loopback_state  #)     �     -   stream_read_from_fx3_state  #)     �     -   stream_write_to_fx3_state  #)     �     ,   B  �  2�  �       2�     �  q  Y  A             .  '  .�     |   A  2�  *�  �     :   fpga_master_states  .�  �     v  2�          >�     :   current_state  >�  �     p   H  :�     6�  �      �     :   
next_state  FQ  �     p   I  Bi     6�  �      �     @     N!     ' Q3     J9  R	      U�     @      N!     v  �\     N!      a�     s   111  �\  a�     :   current_mode  a�  �     p   J  ]�     U�  Y�      �     @     iy     ' Q3     e�  ma      qI     @      iy     v  �\     iy      }     s   111  �\  }     :   MASTER_IDLE  }  �     !   N  y     qI  u1  �     @     ��     ' Q3     ��  ��      ��     @      ��     v  �\     ��      �Y     s   001  �\  �Y     :   LOOPBACK  �Y  �     !   O  �q     ��  ��  �     @     �)     ' Q3     �A  �      ��     @      �)     v  �\     �)      ��     s   010  �\  ��     :   
STREAM_OUT  ��  �     !   P  ��     ��  ��  �     @     ��     ' Q3     ��  �i      �Q     @      ��     v  �\     ��      �	     s   100  �\  �	     :   	STREAM_IN  �	  �     !   Q  �!     �Q  �9  �     v Q3          ީ     @     ީ     :   DATA_BIT  ީ  �    � !   S  ��     ��  ��  �     @     �y      l�     �  ��      �a     v ��     �y      �     @            :   lcd_text_line1  �  �     p   W  �1     �a  ��      �     
     �y  �  ��       �a     �  �     @    �      l�    �  ��     	�     v ��    �     Y     @            :   lcd_text_line2 Y  �     p   X q    	� )      �     
    �  � )      	�    A Y     @    $�     ' Q3    ! (�     ,�     @     $�     v  �\    $�     4�     :   lcd_data_to_send 4�  �     p   Y 0�    ,� <i      �     
    $�  � <i      ,�    8� 4�     :   lcd_goto D9  �     p   Y @Q    ,� L	      �     
    $�  � L	      ,�    H! D9     v  ��         W�     :   lcd_data_request W�  �     p   Z S�    O�  �      �     :   	lcd_clear _�  �     p   Z [�    O�  �      �     :   lcd_goto_request ga  �     p   Z cy    O�  �      �     :   lcd_request_served o1  �     p   Z kI    O�  �      �     :   lcd_display_ready w  �     p   Z s    O�  �      �     -   start �A      �     -   clearscr �A     �     -   move1 �A     �     -   move2 �A     �     -   idle �A     �     -   send1 �A     �     -   send2 �A     �     ,   \ z� ��  �      ��    z� ~� �� �� �� �q �Y             . �) ��     |   [ �� �  �     :   
lcd_states ��  �     v ��         ��     :   lcd_current_state ��  �     p   e ��    �� z�      �     :   clock100 �i  �     p   i ��    O�  �      �     :   lcd_clock50 �9  �     p   j �Q    O�  �      �     :   
reset_fpga �	  �     p   k �!    O�  \      �     @    ��     ' Q3    �� ��     ة     @     ��     v  �\    ��     �y     :   address_get �y  �     p   l ܑ    ة �I      �     
    ��  � �I      ة    �a �y     :   
pktend_get �  �     p   m �1    O�  �      �     :   slwr_get ��  �     p   n �    O�  �      �     :   sloe_get ��  �     p   o ��    O�  �      �     :   slrd_get �  �     p   p �    O�  �      �     :   slcs_get Y  �     p   q q    O�  �      �     :   flag_get )  �     p   r A    O�  �      �     S  #     �� �        2� @         @    &�     ' Q3    "� *�     .�     @     &�     v  �\    &�     :Q     @            :   data_in_get :Q  �     p   s 6i    .� B!      �     
    &�  � B!      .�    >9 :Q     S  #     �� I�        ]y @    F	     @    Q�     ' Q3    M� U�     Y�     @     Q�     v  �\    Q�     eI     @            :   data_out_get eI  �     p   t aa    Y� m      �     
    Q�  � m      Y�    i1 eI     S  #     �� t�        �q @    q     @    |�     ' Q3    x� ��     ��     @     |�     v  �\    |�     �A     @            :   data_out_get2 �A  �     p   u �Y    �� �      �     
    |�  � �      ��    �) �A     :   stream_in_mode_active ��  �     p   y ��    O�  �      �     S  #     �� ��        �9 @    ��     @    ��     ' Q3    �� �i     �Q     @     ��     v  �\    ��     ��     @            s   1111000011110000  �\ ��     :   data_stream_in ��  �     p   z �	    �Q �!      �     :   slwr_stream_in ��  �     p   { ��    O�  �      �     :   stream_out_mode_active ֑  �     p    ҩ    O�  �      �     S  #     �� �a        �� @    �y     @    �1     ' Q3    �I �     �     @     �1     v  �\    �1     ��     @            s   1111000011110000  �\ ��     :   data_stream_out ��  �     p   � ��    � ��      �     S  #     �� q        � @    �     @    A     ' Q3    	Y )          @     A     v  �\    A     $�     @            s   1111000011110000  �\ $�     :   data_stream_out_to_show $�  �     p   �  �     �      �     :   sloe_stream_out ,�  �     p   � (�    O�  �      �     :   slrd_stream_out 4Q  �     p   � 0i    O�  �      �     S  #     �� <!        O� @    89     @    C�     ' Q3    @	 G�     K�     @     C�     v  �\    C�     [a     @            s   0101000001010000  �\ [a     :   data_loopback_in [a  �     p   � Wy    K� S�      �     S  #     �� c1        v� @    _I     @    k     ' Q3    g n�     r�     @     k     v  �\    k     �q     @            s   0101000001010000  �\ �q     :   data_loopback_out �q  �     p   � ~�    r� z�      �     :   loopback_mode_active �A  �     p   � �Y    O�  �      �     :   slwr_loopback �  �     p   � �)    O�  �      �     :   sloe_loopback ��  �     p   � ��    O�  �      �     :   slrd_loopback ��  �     p   � ��    O�  �      �     :   loopback_address ��  �     p   � ��    O�  �      �         �Q �! �� �� Б        �9 �	 �� ̩ �y         �I     :   CLKIN_IN �9 �i     p   � �Q     O�         �i     :   RST_IN �	 �i     p   � �!     O�         �i     :   CLKIN_IBUFG_OUT �� �i     p   � ��    O�         �i     :   CLK0_OUT ̩ �i     p   � ��    O�         �i     :   	CLK2X_OUT �y �i     p   � Б    O�         �i     :   slave_fifo_dcm_1flag �I  �        � �a �i  �         � �� � �� Y � 29 :	 A� YI a h� p�        � �� �� �q A � 6! =� E� ]1 e l� t�         |q     :   clock50 � �1     p   � �     O�         �1     :   reset �� �1     p   � ��     O�         �1     :   lcd_e �� �1     p   � �    O�         �1     :   lcd_rs �q �1     p   � ��    O�         �1     :   lcd_rw A �1     p   � Y    O�         �1     @         ' Q3    ) �     �     @          v  �\         �     :   lcd_data � �1     p   � �    �         �1     @    &�     ' Q3    "� *i     .Q     @     &�     v  �\    &�     6!     :   lcd_data_to_send 6! �1     p   � 29     .Q         �1     :   lcd_data_request =� �1     p   � :	     O�         �1     :   	lcd_clear E� �1     p   � A�     O�         �1     @    M�     ' Q3    I� Qy     Ua     @     M�     v  �\    M�     ]1     :   lcd_goto ]1 �1     p   � YI     Ua         �1     :   lcd_goto_request e �1     p   � a     O�         �1     :   lcd_request_served l� �1     p   � h�    O�         �1     :   lcd_display_ready t� �1     p   � p�    O�         �1     :   lcd_controller |q  �        � x� �1  �         �A � �� �� �� Ʃ        �) �� �� �� �i ʑ         �a     :   clock100 �) �Y     p   � �A     O�         �Y     :   flag_get �� �Y     p   � �     O�         �Y     :   reset �� �Y     p   � ��     O�         �Y     :   stream_in_mode_active �� �Y     p   � ��     O�         �Y     :   slwr_stream_in �i �Y     p   � ��    O�         �Y     S  #     �� �9        �� @    �Q     @    �	     ' Q3    �! ��     ��     @     �	     v  �\    �	     ʑ     @            :   data_stream_in ʑ �Y     p   � Ʃ    ��         �Y     :   slave_fifo_stream_write_to_fx3 �a  �        � �y �Y  �         �1 � �� � � 7� ?� G�        � �� �� �� � ;� C� Ky         SI     :   clock100 � �I     p   � �1     O�         �I     :   flag_get �� �I     p   � �     O�         �I     :   reset �� �I     p   � ��     O�         �I     :   stream_out_mode_active �� �I     p   � �     O�         �I     S  #     �� �Y        � @    �q     @    )     ' Q3    A 	     �     @     )     v  �\    )     �     @            :   data_stream_out � �I     p   � �     �         �I     S  #     ��  �        4	 @    �     @    (Q     ' Q3    $i ,9     0!     @     (Q     v  �\    (Q     ;�     @            :   data_stream_out_to_show ;� �I     p   � 7�    0!         �I     :   sloe_stream_out C� �I     p   � ?�    O�         �I     :   slrd_stream_out Ky �I     p   � G�    O�         �I     :   slave_fifo_stream_read_from_fx3 SI  �        � Oa �I  �         [ b� � �9 �	 �� �� �y �I � ��        _ f� �� �! �� �� đ �a �1 � ��         �     :   clock100 _ W1     p   � [     O�         W1     :   reset f� W1     p   � b�     O�         W1     S  #     �� n�        �) @    j�     @    vq     ' Q3    r� zY     ~A     @     vq     v  �\    vq     ��     @            :   data_loopback_in �� W1     p   � �     ~A         W1     S  #     �� ��        �Q @    ��     @    ��     ' Q3    �� ��     �i     @     ��     v  �\    ��     �!     @            :   data_loopback_out �! W1     p   � �9    �i         W1     :   loopback_mode_active �� W1     p   � �	     O�         W1     :   flag_get �� W1     p   � ��     O�         W1     :   slwr_loopback đ W1     p   � ��    O�         W1     :   sloe_loopback �a W1     p   � �y    O�         W1     :   slrd_loopback �1 W1     p   � �I    O�         W1     :   loopback_address � W1     p   � �    O�         W1     :   buffer_empty_show �� W1     p   � ��    O�         W1     :   slave_fifo_loopback �  �        � � W1  �         �Y        �A         �     v  �\         �A     :   vector �A �     !   � �Y     �q     �     :   vector_to_string �  �     v ��         �     5   � �)        �\ �� �   �         i 5� �    "Q 9�        �i �Q �9     @     �      �    � �     "Q     @    �     @     "Q     :   i "Q 
�     �   � i    � � 
�     @    *!      l�    &9 .	     1�     @    *!     v ��    *!     9�     :   result 9� 
�     �   � 5�    1� A� 
�     
    *!  � A�      1�    =� 9�     @     Ia      �    Ey MI     U     @    Ia         Y        U Ia    �� �i     !   � Y     Ia Ia Q1     :   i U Q1     >    �Y Y `�     S ��    \�  \ ��     S �c    Y h� l�     @    d�     >    5� d� pq     �   �     �� l� ��     S �c    Y xA |)     @    tY     >    5� tY �     �   �     �k |) ��     r          �;    � ��     v  ��         ��     U     ��     FT  FT  �� ��  �     T   = ��  �     r         `�    pq ��     <   �        �� �� Q1     4   �     Q1 
�     l   �     5� 
�     t     �) 
�  �     \    �Q  e� ��     \    �!  \ ��     } ��     \    �� �� ��     \    �� �Q ��     \    Б �� ��        � �y �a    �! �	 �� �� ��      �     :   inst_slave_fifo_dcm �a  �     E   � �y ��  �     \    � �Q �     \    ��  \ �     \    � @R �     \    �� H" �     \    Y O� �     \    � kJ �     \    29 0� �     \    :	 S� �     \    A� [� �     \    YI @Q �     \    a cy �     \    h� kI �     \    p� s �        �  � x�    �I �1 � � �� �� � � � �q �Y �A �)      �     :   inst_lcd_controller �  �     E   �  � �  �     \    �A �� $!     \    � A $!     S �\    (	 �     \    �� � $!     \    �� �� $!     \    �� �� $!     \    Ʃ �	 $!        � +� �y    � � � i Q  9      �     Y    �� �!         :   inst_stream_write_to_fx3 /�  �     E   � +� $!  �     \    �1 �� V�     \    � A V�     S �\    Z� ?y     \    �� ;� V�     \    � ҩ V�     \    � �� V�     \    7�  � V�     \    ?� (� V�     \    G� 0i V�        ^� Oa    3� 7� ?y Ca GI K1 O S      �     Y    �� �!         :   int_stream_read_from_fx3 b�  �     E   ^� V�  �     \    [ �� �i     S �\    �Q nY     \    b� jq �i     \    � Wy �i     \    �9 ~� �i     \    �	 �Y �i     \    �� A �i     \    �� �) �i     \    �y �� �i     \    �I �� �i     \    � �� �i     \    ��  �� �i        �9 �    f� nY rA v) z }� �� �� �� �� ��      �     Y    �� �!         :   inst_loopback �!  �     E   �9 �i  �     � ��         ��            �	  mb              �     �  u2         ��             �� �!              �     �  D         ��       "     �� s              �     �  D         �a       #     �y  ��              �     s   11  �\ �1     � �I         �       $     �1 r              �     �  D         ��       %     � �1              �                         P� T�     S ��    �!  D M     s   00  �\ �     � ߡ         �q     o  +     �  �"         M     �  D         �A     o  ,     �Y !         M     �  D         �     o  -     �) B         M     �  D         ��     o  .     �� (�         M     �  D         �     o  /     � 0�         M     �  D         �     o  0     
�  �2         M     S �4    E1 I     � ܑ         9     o  2     Q  �"         I     � �         "	     o  3     ! !         I     � q         )�     o  4     %� B         I     � �         1�     o  5     -� (�         I     � ��         9y     o  6     5� 0�         I     � �1         AI     o  7     =a  �2         I     Y    �d ��         r         i    9 "	 )� 1� 9y AI P�     r         ۹    �q �A � �� � � P�     <  *        M I ��     a  )     ��    �!  :� �� �)  �                         �1 �     S �Q     :�  A �I     � �	         dq     o  ?     `� aa         �I     S �Q     :�  q �9     S �]    {� � ��     s   0000000000000000  �\ lA     � ~�         w�     o  B     t aa         ��     Y    v� ~�         Y    ~� p)         r         lA    w� ��     <  A        �� �9     v  ��         �i     U     �Q     2�  2�  �� ��  �     T   = �i  �     r         hY    �� �1     V         �	     
    ��  \ ��      Y�    �	 ��     � ��         �y     @     ��     @    ��     ' Q3    �� ��     �	     o  E     �� aa         �a     r          �;    �y �1     r         \�    dq �1     <  >        �I �9 �a X�     a  =     X�     :� ~�  �                         	� 	i     S ��    �!  D 	�     V         չ     
    �A  \ ١      ��    չ ݉     � ١         �)     @     �A     @    �A     ' Q3    �Y �q     չ     o  M     ݉ �Y         	�     S �4    �� 	 �     � aa         ��     o  O     �� �Y         	 �     Y    �d ��         r         �    �� 	�     r         ��    �) 	�     <  L        	� 	 � �     a  K     �    �! ��  �                         	;I 	?1     S ��    �  \ 	7a     � �Y         		     o  W     	!  �b         	7a     V      � 	#�     
    	�  #, 	'�       �    	#� 	+�     � 	'�         	/�     o  Y     	+�  �b         	3y     r          �;    	/� 	;I     r         	9    		 	;I     <  V        	7a 	3y 	Q     a  U     	Q    �  �                         	�� 	��     S ��    �!  D 	}�     V         	N�     
    	bY  \ 	R�      .�    	N� 	V�     � 	R�         	fA     @     	bY     @    	bY     ' Q3    	^q 	Z�     	N�     o  a     	V� 6i         	}�     S �4    	u� 	y�     �  �b         	q�     o  c     	n 6i         	y�     Y    �d ��         r         	j)    	q� 	��     r         	G    	fA 	��     <  `        	}� 	y� 	C     a  _     	C    �! ��  :�  �                         
-y 
1a     S �Q     :�  q 
)�     � 6i         	�!     o  k     	�9 Wy         
)�     V         	��     
    	�y  \ 	��      �    	�� 	��     � 	��         	�a     @     	�y     @    	�y     ' Q3    	�� 	��     	��     o  l     	�� ��         
)�     S �Q     :�  Y 	�A     � 6i         	�     o  n     	�1 ��         	�A     V         	��     
    	�q  \ 	��      K�    	�� 	Ϲ     � 	��         	�Y     @     	�q     @    	�q     ' Q3    	׉ 	ӡ     	��     o  o     	Ϲ Wy         	�A     r         	�I    	� 	�Y 
-y     V         	�     
    	��  \ 	��      �    	� 	��     � 	��         
�     @     	��     @    	��     ' Q3    	�� 	��     	�     o  q     	�� ��         
%�     V         

Q     
    
�  \ 
9      K�    

Q 
!     � 
9         
!�     @     
�     @    
�     ' Q3    
� 
	     

Q     o  r     
! Wy         
%�     r          �;    
� 
!� 
-y     r         	�Q    	�! 	�a 
-y     <  j        
)� 	�A 
%� 	�i     a  i     	�i     :� 0i  �                         
\Y 
`A     S ��    �!  D 
Xq     �  \         
A     o  z     
= A         
Xq     S �4    
P� 
T�     � 8�         
L�     o  |     
H� A         
T�     Y    �d ��         r         
D�    
L� 
\Y     r         
91    
A 
\Y     <  y        
Xq 
T� 
5I     a  x     
5I    �! ��  �                         
�i 
�� 
�� 
��     S �Q     :�  q 
�     �  D         
o�     o  �     
k� �Y         
�     �  \         
w�     o  �     
s� �Y         
{�     r          �;    
w� 
�i     r         
h    
o� 
�i     <  �        
� 
{� 
d)     S �Q     :�  Y 
��     �  D         
�!     o  �     
�9 ҩ         
��     �  \         
��     o  �     
�	 ҩ         
��     r          �;    
�� 
��     r         
�Q    
�! 
��     <  �        
�� 
�� 
d)     S �Q     :�  A 
�     �  D         
�a     o  �     
�y ��         
�     �  \         
�1     o  �     
�I ��         
�     r          �;    
�1 
��     r         
��    
�a 
��     <  �        
� 
� 
d)     a  �     
d)     :�  �                         e� i�     S �Q     :�  A b     �  \         
�q     o  �     
щ q         b     �  D         
�A     o  �     
�Y ��         b     �  D         
�     o  �     
�) �         b     � ��         
��     o  �     
�� �         b     S �Q     :�  Y �     �  \         
��     o  �     
�� q         �     � (�          i     o  �     
�� ��         �     � 0i         9     o  �     Q �         �     �  D         	     o  �     ! �         �     r         
��    
��  i 9 	 e�     S �Q     :�  q ;     �  \         �     o  �     � q         ;     � ��         'y     o  �     #� ��         ;     � ��         /I     o  �     +a �         ;     � �)         7     o  �     31 �         ;     r         �    � 'y /I 7 e�     �  D         B�     o  �     >� q         ^)     �  D         J�     o  �     F� ��         ^)     �  D         Rq     o  �     N� �         ^)     �  D         ZA     o  �     VY �         ^)     r          �;    B� J� Rq ZA e�     r         
͡    
�q 
�A 
� 
�� e�     <  �        b � ; ^) 
ɹ     a  �     
ɹ     :�  �                         �� ��     S �Q     :�  Y y�     S ��    ��  D y�     S �{    q� u� ��     s   11  �\ �Q     � }i         �9     o  �     �Q ܑ         ��     s   00  �\ �	     � �!         ��     o  �     �	 ܑ         ��     r          �;    �� ��     r         y�    �9 ��     <  �        �� �� m�     a  �     m�     :� ��  �                         �! �	     S ��    �!  D 9     �  �         �1     o  �     �I  :�         9     �  y         �     o  �     �  ]�         9     s   FSM FPGA         �� ��     � ��         ù     o  �     ��  �1         9     s   MODE: RESET      �� ˉ     � ǡ         �q     o  �     ˉ q         9     S �4    wi {Q     �  Bi         �)     o  �     �A  :�         {Q     �  �         ��     o  �     �  ]�         {Q       �        
	 -1 PY s�  :� {Q     s   FSM: LOOPBACK    �� �     � ��         �     o  �     �  �1         
	     S �)    �Q �i     � ��         9     Y    �Y ~�         o  �     �i q         
	          q 
	     r         !    � 9 ��     s   FSM: STREAM OUT  �� �     � �         �     o  �     �  �1         -1     S �)    !y �     � �         %a     Y    �Y  �         o  �     � q         -1          Y -1     r         )I    � %a ��     s   FSM: STREAM IN   �� 5     � 1         8�     o  �     5  �1         PY     S �)    D� @�     � <�         H�     Y    �Y �	         o  �     @� q         PY          A PY     r         Lq    8� H� ��     V         o�     s   FSM FPGA 1       �� \     � X)         _�     o  �     \  �1         s�     s   MODE: IDLE STATE �� g�     � c�         k�     o  �     g� q         s�         TA s�     r         o�    _� k� ��     Y    �d ��         r         �Y    �) �� �� �!     r         �a    �1 � ù �q �!     <  �        9 {Q �y     a  �     �y    �� �!  �                         �� �� uQ     �  :�         ��     o  �     ��  Bi         ��       �        �i � :� ]� qi  :� ��     S (�    �� �� �     �  q         �a     o  �     �y  Bi         �     S (�    � �� ��     �  Y         �     o  �     �1  Bi         ��     Y    �  ]�         Y     �  ��         r         �I    � �     S (�    �q �Y �A     �  A         ŉ     o  �     ��  Bi         �A     Y    �  ]�         Y     �  �!         r         ��    ŉ �     �  �         �     o  �     �)  Bi         ��     r          �;    � �     Y    �  ]�         Y     �  �q         r         ��    �a �     <  �        � �� �A �� �i          � �i     r         ��    � ��     S �]    	 � �     �  �          !     o  �     �9  Bi         �     Y    v�  ]�         Y    ~�  �q         r         �Q     ! �     <  �        � �          q �     r         �    � ��     S �]    '1 + /     �  �         #I     o  �     a  Bi         /     Y    v�  ]�         Y    ~�  ��         r         y    #I 2�     <  �        / :�          Y :�     r         6�    2� ��     S �]    JY NA R)     �  �         Fq     o  �     B�  Bi         R)     Y    v�  ]�         Y    ~�  �!         r         >�    Fq V     <  �        R) ]�          A ]�     r         Y�    V ��     V         m�     �  �         i�     o  �     e�  Bi         qi         a� qi     r         m�    i� ��     a  �     ��     :�  ]�  �         �� �a        �� �I        �� ��     @     �	      �    }! ��     ��     @��� �	     @    ��     :   counter �� y9     �  � ��    �	 �� y9     v �         �I     @     �I     :   letter_index �I y9     �  � �a    �� �y y9     S �4    �	 ��       �        �� �� a oQ �9 M� ֱ �i �� ��     � z�         ��     o  �     � ��         ��         �� ��     r         ��    �� �     S ��    s  D �)     @     �q     �        �� �� �)     � ��         �A     o       �Y ��         �)     r         ��    �q �A �     <  �        �) ��         z� ��     r         ��    � �     S w�    �� � �     @    ��     �  D         �     o       � [�         �     S ��    kI  D 	�     �  \         �9     o       �Q [�         	�     � ��         �	     o       �! ��         	�     @     �     �  	     � �� 	�     r         �i    �9 �	 � �     r         ��    � �     <          � 	� a         ~� a     r         y    � �     S w�    �� !1 c�     @    I     s   10000000  �\ )     � %         ,�     o       ) @Q         c�     �  D         4�     o       0� cy         c�     S ��    kI  D DY     S 7    �� @q DY     @ А <�     S ��    8� <� _�     �  \         L)     o       HA cy         _�     � �q         S�     o       P ��         _�     @     [�     �       W� �� _�     r         DY    L) S� [� g�     r         I    ,� 4� g�     <          c� _� oQ         �� oQ     r         ki    g� �     S w�    �� w! �     @    s9     S �c    �a ~� ��     @    {	     �       {	 �a �      �    �  y �� �y     >     �1 �a         @    �y     S �^    �I �1 �a     � �y         �     Y    �� ��         Y    �� ��         o       �a 0�         �     �  D         ��     o       � S�         �     S ��    kI  D ��     �  \         ��     o       �� S�         ��     @     �q     �       �� �� ��     S w�    �a �A ��      �     �1  u3 �� �Y     � ��         �     o       �) ��         ��     @            @            r         �Y    � ܱ     <          �� ��     r         ��    �� �q ܱ �i     r         s9    �� � �� �i     <          � �� �9         �q �9     r         �Q    �i �     S w�    �� �	 BA     @    �!     s   11000000  �\ ��     � ��         �     o  "     �� @Q         BA     �  D         �     o  #     � cy         BA     S ��    kI  D 1     S 7    �� I 1     @ А a     S ��    y a >Y     �  \         #     o  %      cy         >Y     � �Y         *�     o  &     &� ��         >Y     @     2�     �  '     .� �� >Y     @     :q     �  (     6� �a >Y     r         1    # *� 2� :q F)     r         �!    � � F)     <  !        BA >Y M�         �� M�     r         J    F) �     S w�    �� U� ��     @    Q�     S �c    �a ]� a�     @    Y�     �  ,     Y� �a ��      �    �  y iQ q!     >    q �a         @    q!     S �^    x� |� u	     � q!         ��     Y    �� ei         Y    �� m9         o  -     u	 0�         ��     �  D         ��     o  .     �� S�         ��     S ��    kI  D �     �  \         �I     o  0     �a S�         �     @     �     �  1     �1 �� �     S w�    �a �� �A      �    q  u3 �q �     � ��         ��     o  3     �� ��         �A     @     ��     �  4     �� �a �A     @            @            r         �    �� �� �)     <  2        �A �     r         �y    �I � �) ��     r         Q�    a� �� �� ��     <  +        �� � ֱ         �Y ֱ     r         ��    �� �     V         ށ         ڙ �i     r         ށ     �     S �c    �� �9 �!     @    �Q     �  9     �Q �� ��     Y    �d �Q         r         �1    � �! ��     <  �        �� y9     a  �     y9    �Q kI  �     %     �  � ~�     � �     �   lC:/Users/MariuszKomp/Desktop/Praca inzynierska/08 Oprogramowanie/1 FLAG/Spartan 3E/slave_fifo_main_1flag.vhd �  �                slave_fifo_main   slave_fifo_arch   work      slave_fifo_main   slave_fifo_arch   work      slave_fifo_main       work      standard       std      std_logic_1164       ieee      std_logic_unsigned       ieee      std_logic_arith       ieee