%%--------------SPEECH COMPRESSION PROJECT---------------%%
%%SHASHANKAR SUDARSAN
%%A53214135
%%LPC -10

clc
clear variables;
close all;

Transmitted
count=716;
win =180;
Fs = 8000;
b = [1, -0.975];
gv = dsp.RCToLPC;
gun = dsp.RCToLPC;

%% Decoder
% Gain Computation
j=1;
for i = 1:count
    if(voiced(i)==0)             
        gain(i) = sqrt(power(i));                   %Computing the gain from the power
    else       
        gain(i) = sqrt(power(i)*pitch(j));
        j=j+1;
    end
end



% Excitation signal

delay=1;
j=1;
for i=1:count
    if(voiced(i)==1)
        n=0;
        % Impulse train for voiced
        for k =1:win
            if k == n*pitch(j)+delay
                excite(i,k) = gain(i)*1;                    %Computing excitation signal from the gain
                n=n+1;
            else
                excite(i,k) = 0;
            end
        end
        delay = find(excite(i,:), 1, 'last' )+pitch(j)-win; %Computing dealay from excitaion signal,pitch and window     
        j=j+1;
    else
        excite(i,:) = gain(i)*rand(1,win);
    end
end

% Synthesis
m=1;
n=1;
synt = [];
for i=1:count
    if(voiced(i)==1)
        lpc_voic(m,:) = gv(rc_v(m,:)');                         % lpc coefficients from reflection coeff
        synth = filter(1,[1 lpc_voic(m,2:end)],excite(i,:));    % Synthesised signal from lpc coefficients
        m=m+1;
    else
        lpc_unvoic(n,:) = gun(rc_unv(n,:)');                    % lpc coefficients from reflection coeff
        synth = filter(1,[1 lpc_unvoic(n,2:end)],excite(i,:));  % Synthesised signal from lpc coefficients
        n=n+1;
    end
    synthes(i,:) = synth;           %Segmented synthesised signal
    synt = [synt synth];
end

% De-Emphasis

recon = filter(abs(b),1,synt);      %Reconstructed signal
sound(recon)
audiowrite('Decoded.wav',recon,Fs);


