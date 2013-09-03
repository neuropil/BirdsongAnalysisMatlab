function menu = menu_play(figh)
% create Play Menu and related actions


menu.play = uimenu('parent',figh, 'label','&Play');
    menu.playnormal = uimenu('parent',menu.play,'label','Song','callback',{@playsong,'Play'});
    menu.playselect = uimenu('parent',menu.play,'label','Selected','callback',{@playsong,'PlaySelect'});
    menu.playselectrepeat = uimenu('parent',menu.play,'label','Repeat Selected','callback',{@playsong,'PlaySelectRepeat'});
%     menu.playslow = uimenu('parent',menu.play,...
%         'label','Slow','callback',{@playsong,'Speed'});

%---------------------------------------------------------------
function playsong(hco,eventStruct,arg)

sbview = get(gcf,'userdata');

soundlength = 0;
switch lower(arg)
    case 'play' % play 
        soundlength = size(sbview.song.d,1)*sbview.song.a.fs;
%         player=audioplayer(sbview.song.d,sbview.song.a.fs);
%         play(player);    
        sound(sbview.song.d, sbview.song.a.fs);
    case 'playselect' % play selected
        soundlength = diff(sbview.timelim);
        indrange = round(sbview.selectlim*(sbview.song.a.fs/1000)); % range of data indices to play
        indrange = [max(indrange(1),1) min(indrange(2),size(sbview.song.d,1))];
%         player=audioplayer(sbview.song.d(indrange(1):indrange(2),:), sbview.song.a.fs);
%         play(player);    
        sound(sbview.song.d(indrange(1):indrange(2),:), sbview.song.a.fs);
    case  'playselectrepeat' % repeat selected 
        repeats = 3; % number of times selected portion is repeated
        gap = 250; % gap in msec between repeats
        soundlength = diff(sbview.selectlim)*repeats/1000+gap*(repeats-1)/1000;
        indrange = round(sbview.selectlim*(sbview.song.a.fs/1000)); % range of data indices to play
        indrange = [max(indrange(1),1) min(indrange(2),size(sbview.song.d,1))];
        selectsound = sbview.song.d(indrange(1):indrange(2),:);
        gapsamples = gap*sbview.song.a.fs/1000;
        repeatsound = selectsound;
        for i=2:repeats
            repeatsound = [repeatsound; zeros(gapsamples,size(sbview.song.d,2)); selectsound];
        end
%         player=audioplayer(repeatsound, sbview.song.a.fs);
%         play(player);    
        sound(repeatsound, sbview.song.a.fs);
%         case 'speed' % play slower
%             if play.Speed == play.SlowSpeed
%                 play.Speed = 1;
%             else
%                 play.Speed = play.SlowSpeed;
%             end
%             set(menu.playspeed,'Label',['Speed = ' num2str(play.Speed)]);
%         case 'reverse' % play reverse
%             if play.IsReversed 
%                 play.IsReversed = 0; checked = 'off';
%             else
%                 play.IsReversed = 1; checked = 'on';
%             end
%             set(menu.playspeed,'Checked',checked);
% end

% pause(soundlength);
end


