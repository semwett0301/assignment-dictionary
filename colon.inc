%macro colon 2
    %ifstr %1
        %ifid %2
            %ifdef l_label
                %2: dq l_label
            %else
                %2: dq 0
            %endif
            %define l_label %2
        %else
            %error "The second parameter is not a label"
        %endif
        db %1, 0
    %else
        %error "The first parameter is not a string"
    %endif
%endmacro