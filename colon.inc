%macro colon 2
    %ifstr %1
        %ifid %2
            %ifdef l_label
                %%some_label: dq l_label
            %else
                %%some_label: dq 0
            %endif
            db %1, 0
            %2:
            %define l_label %%some_label
        %else
            %error "The second parameter is not a label"
        %endif
    %else
        %error "The first parameter is not a string"
    %endif
%endmacro