function labelchar = maplabelchar(keystr)
% labelchar = maplabelchar(keystr)
% takes typed in key string and returns appropriate label character

labelchar = keystr;
if length(keystr)==1
        switch lower(keystr)
            case 'i'
                labelchar = 'Int';
             case 't'
                labelchar = 'Tet';
             case 'u'
                labelchar = 'Call';
              case 'v'
                labelchar = 'DCall';
            case 'x'
                labelchar = 'X';
            case 'y'
                labelchar = 'Ch2';
            case 'z'
                labelchar = 'Nz';
        end
    end
end
