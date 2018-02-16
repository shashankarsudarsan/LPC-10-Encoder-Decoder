%%--------------SPEECH COMPRESSION PROJECT---------------%%
%%SHASHANKAR SUDARSAN
%%A53214135
%%LPC -10

clc
clear variables;
close all;


[s, Fs] = audioread('Sample.wav');      % Reading input audio signal
s2=s;           
s=s(1:129000);
len = length(s);
win = 180;                              % Defining window length as 180
w = hamming(win);                       % Windowing using Hamming window
hv = dsp.LPCToRC;       
hun = dsp.LPCToRC;


%% Encoder
% Pre-Emphasis
b = [1, -0.975];
sfil = filter(b,1,s);                   % pre-emphasis filtering

% Segmenting
count=1;
for i=1:win:len-win+1
   seg(count,:) = sfil(i:i+(win-1)); 
   count=count+1;                       % no of segments = count
end
count = count-1;

% Voicing Detector
% Using Zero Crossing
for i =0:count-1
   for j =1:win
       if(i==0)
           j=2;
       end
       temp(j) = abs(sign(sfil(i*win+j))-sign(sfil(i*win+j-1)));
   end
   zc(i+1)=sum(temp);
end
for i =1:count
    if zc(i)>mean(zc)                     % Detecting Zero crossing
        voiced(i)=0;
    else
        voiced(i)=1;
    end
end
tags = 90:win:win*(count)-90;
% figure
% plot(s)
% hold on;
% plot(tags,voiced)

% Levinson-Durbin to find PARCOR (LP Analysis)
M=10;
j=1;
k=1;
for i=1:count
    if voiced(i) == 0
        seg_w(i,:) = w'.*seg(i,:);
        lpc_unv(j,:) = lpc(seg_w(i,:),4); % determining LPC coefficients
        rc_unv(j,:) = hun(lpc_unv(j,:)'); % determining the RCs from LPCs
        j=j+1;
    elseif voiced(i) == 1
        seg_w(i,:) = w'.*seg(i,:);
        lpc_v(k,:) = lpc(seg_w(i,:),10);
        rc_v(k,:) = hv(lpc_v(k,:)');
        k=k+1;
    end 
end

% Prediction error signal
j=1;
k=1;
err = [];
est = [];
for i = 1:count
    if voiced(i) == 0
        est_seg = filter([0 -lpc_unv(j,2:end)],1,seg(i,:));
        e = seg(i,:)-est_seg;
        j=j+1;
    elseif voiced(i) == 1
        est_seg = filter([0 -lpc_v(k,2:end)],1,seg(i,:));
        e = seg(i,:)-est_seg;
        k=k+1;
    end
    er(i,:) = e;
    err = [err e];
    est = [est est_seg];
end

% Pitch estimation using amdf
p=1;
Fpass = 850/8000;
Fstop = 950/8000;
Ap = 1;
Ast = 30;
d = designfilt('lowpassfir','PassbandFrequency',Fpass,'StopbandFrequency',Fstop,'PassbandRipple',Ap,'StopbandAttenuation',Ast);     %Designing filter with the above-defined specifications.
for i =1:count
    if voiced(i)==1
        err_filt =filter(d,er(i,:)); % pitch is calculated from the error signal for better results
        len =length(err_filt);
        %AMDF
        lags = 180;
        amd = zeros(1,lags);            
        err_filt = err_filt';
        err_filt = [err_filt; zeros(lags,1)];
        for k=1:lags
            for j=1:len
                amd(k) = amd(k)+abs(err_filt(j+k)-err_filt(j));
            end
             amd(k) = amd(k)/len;
        end
        temp(p,:)=amd;
        pitch(p) = find(amd == min(amd(25:80)));    
        p=p+1;
    end
     
end


% Power computation
j=1;
for i = 1:count
    if(voiced(i)==0)
        power(i) = 1/win.*(er(i,:)*er(i,:)');       % Computing power using the prediction error signal       
    else
        lim = floor(win./pitch(j)).*pitch(j);
        power(i) = (1/lim).*(er(i,1:lim)*er(i,1:lim)');    
        j=j+1;
    end
end
sound(sfil)
audiowrite('Encoded.wav',sfil,Fs);

% saving matrices
save('refv.mat','rc_v'); % Reflection Coefficients
save('refunv.mat','rc_unv');
save('pit.mat','pitch'); % Pitch Periods
save('powe.mat','power'); % Power Computed
save('voic.mat','voiced'); % Voiced/Unvoiced

