%% Forward Error Correction in wireless communication using FPGA
M = 16;            % Modulation order
k = log2(M);       % Bits per symbol
numBits = k*2.5e5; % Total bits to process
sps = 4;           % Samples per symbol (oversampling factor)
filtlen = 10;      % Filter length in symbols
rolloff = 0.25;    
rng default;                     % Default random number generator
dataIn = randi([0 1],numBits,1);
constrlen = [5 4];          % Code constraint length
genpoly = [23 35 0; 0 5 13]
tPoly = poly2trellis(constrlen,genpoly);
codeRate = 2/3;
dataEnc = convenc(dataIn,tPoly);
dataSymbolsIn = bit2int(dataEnc,k);
dataMod = qammod(dataSymbolsIn,M);
rrcFilter = rcosdesign(rolloff,filtlen,sps);
txSignal = upfirdn(dataMod,rrcFilter,sps,1);
EbNo = 10;
snr = convertSNR(EbNo,'ebno', ...
    samplespersymbol=sps, ...
    bitspersymbol=k,CodingRate=codeRate);
rxSignal = awgn(txSignal,snr,'measured');
rxFiltSignal = ...
    upfirdn(rxSignal,rrcFilter,1,sps);       
rxFiltSignal = ...
    rxFiltSignal(filtlen + 1:end - filtlen); 
dataSymbOut = qamdemod(rxFiltSignal,M);
codedDataOut = int2bit(dataSymbOut,k);
traceBack = 16;                      % Decoding traceback length
numCodeWords = ...
    floor(length(codedDataOut)*2/3); % Number of complete codewords
dataOut = ...
    vitdec(codedDataOut(1:numCodeWords*3/2), ...
    tPoly,traceBack,'cont','hard');  % Decode data
decDelay = 2*traceBack;              % Decoder delay, in bits
[numErrors,ber] = ...
   biterr(dataIn(1:end - decDelay),dataOut(decDelay + 1:end));       
fprintf('\nThe bit error rate is %5.2e, based on %d errors.\n', ...
    ber,numErrors)

%% Polarized Convolutional Encoder
%	--Adaptive Frozen Polar Coding polarization transformation 
nVar = 1.0; 
chan = comm.AWGNChannel('NoiseMethod','Variance','Variance',nVar);
K = 132;
E = 256;
msg = randi([0 1],K,1,'int8');
enc = nrPolarEncode(msg,E);
mod = nrSymbolModulate(enc,'QPSK');
rSig = chan(mod);
rxLLR = nrSymbolDemodulate(rSig,'QPSK',nVar); 
L = 8;
rxBits = nrPolarDecode(rxLLR,K,E,L);
numBitErrs = biterr(rxBits,msg);
disp(['Number of bit errors: ' num2str(numBitErrs)])
%	--convolution codes using generator polynomials 
trellis = poly2trellis(3,[6 7])
data = randi([0 1],70,1);
codedData = convenc(data,trellis);
tbdepth = 34;
decodedData = vitdec(codedData,trellis,tbdepth,'trunc','hard');
biterr(data,decodedData)
trellis = poly2trellis([5 4],[23 35 0; 0 5 13])
trellis.nextStates(1:5,:)
trellis = poly2trellis(5,[37 33],37)
data = randi([0 1],70,1);
codedData = convenc(data,trellis);
tbdepth = 34; % Traceback depth for Viterbi decoder
decodedData = vitdec(codedData,trellis,tbdepth,'trunc','hard');
biterr(data,decodedData)

%% Flexible Turbo Decoder
%	--Reed-Solomon Euclid to detect errors 
m = 3;                   % Number of bits per symbol
n = 2^m-1;               % Codeword length
k = 3;                   % Message length
msg = gf([2 7 3; 4 0 6; 5 1 1],m);
code = rsenc(msg,n,k);
errors = gf([2 0 0 0 0 0 0; 3 4 0 0 0 0 0; 5 6 7 0 0 0 0],m);
noisycode = code + errors;
[rxcode,cnumerr] = rsdec(noisycode,n,k);
%	--Euclidean algorithm to locates the error
cfa = [1 3 5 7];
cfb = [1 2];
lpA = laurentPolynomial(Coefficients=cfa,MaxOrder=2);
lpB = laurentPolynomial(Coefficients=cfb);
dec = euclid(lpA,lpB);
numFac = size(dec,1);
for k=1:numFac
    q = helperPrintLaurent(dec(k,1).LP);
    r = helperPrintLaurent(dec(k,2).LP);
    fprintf('Euclidean Division #%d\n',k)
    fprintf('Quotient: %s\n',q)
    fprintf('Remainder:  %s\n \n',r)
end
for k=1:numFac
    q = dec(k,1).LP;
    r = dec(k,2).LP;
    areEqual = (lpA==lpB*q+r);
    fprintf('Euclidean Division #%d: %d\n',k,areEqual)
end


%	--Sequential Concatenated Turbo coding
blkLen = 10;
trellis = poly2trellis(4,[13 15],13);
n = log2(trellis.numOutputSymbols);
mLen = log2(trellis.numStates);
fullOut = (1:(mLen+blkLen)*2*n)';
outLen = length(fullOut);
netRate = blkLen/outLen;
data = randi([0 1],blkLen,1);
intIndices = randperm(blkLen);

turboEnc = comm.TurboEncoder('TrellisStructure',trellis);
turboEnc.InterleaverIndices = intIndices;
turboEnc.OutputIndicesSource = 'Property';
turboEnc.OutputIndices = fullOut;

encMsg = turboEnc(data);   % Encode

disp(['Turbo coding rate: ' num2str(netRate)])
encOutLen = length(encMsg)
isequal(encOutLen,outLen)  
puncOut = getTurboIOIndices(blkLen,n,mLen);
outLen = length(puncOut);
netRate = blkLen/outLen;
data = randi([0 1],blkLen,1);
intIndices = randperm(blkLen);

turboEnc = comm.TurboEncoder('TrellisStructure',trellis);
turboEnc.InterleaverIndices = intIndices;
turboEnc.OutputIndicesSource = 'Property';
turboEnc.OutputIndices = puncOut;
encMsg = turboEnc(data);   % Encode
disp(['Turbo coding rate: ' num2str(netRate)])
encOutLen = length(encMsg)
isequal(encOutLen, outLen)


%% Adaptive Polar Coding with reversed polarization transformation
modOrder = 16;               % Modulation order
bps = log2(modOrder);        % Bits per symbol
EbNo = (2:0.5:4);            % Energy per bit to noise power spectral density ratio in dB
EsNo = EbNo + 10*log10(bps); % Energy per symbol to noise power spectral density ratio in dB
rng(1963);
turboEnc = comm.TurboEncoder('InterleaverIndicesSource','Input port');
turboDec = comm.TurboDecoder('InterleaverIndicesSource','Input port','NumIterations',4);
trellis = poly2trellis(4,[13 15 17],13);
n = log2(turboEnc.TrellisStructure.numOutputSymbols);
numTails = log2(turboEnc.TrellisStructure.numStates)*n;
errRate = comm.ErrorRate;
ber = zeros(1,length(EbNo));
for k = 1:length(EbNo)
    % numFrames = 100;
    errorStats = zeros(1,3);
    %for pktIdx = 1:numFrames
    L = 500*randi([1 3],1,1);         % Packet length in bits
    M = L*(2*n - 1) + 2*numTails;     % Output codeword packet length
    rate = L/M;                       % Coding rate for current packet
    snrdB = EsNo(k) + 10*log10(rate); % Signal to noise ratio in dB
    noiseVar = 1./(10.^(snrdB/10));   % Noise variance
    
    while errorStats(2) < 100 && errorStats(3) < 1e7
        data = randi([0 1],L,1);
        intrlvrIndices = randperm(L);
        encodedData = turboEnc(data,intrlvrIndices);
        modSignal = qammod(encodedData,modOrder, ...
            'InputType','bit','UnitAveragePower',true);
        rxSignal = awgn(modSignal,snrdB);
        demodSignal = qamdemod(rxSignal,modOrder,'OutputType','llr', ...
            'UnitAveragePower',true,'NoiseVariance',noiseVar);
        rxBits = turboDec(-demodSignal,intrlvrIndices); % Demodulated signal is negated
        errorStats = errRate(data,rxBits);
    end
    
    ber(k) = errorStats(1);
    reset(errRate)
end
semilogy(EbNo,ber,'-o')
grid
xlabel('Eb/No (dB)')
ylabel('Bit Error Rate')
uncodedBER = berawgn(EbNo,'qam',modOrder); % Estimate of uncoded BER
hold on
semilogy(EbNo,uncodedBER)
legend('Adaptive Polar','Polar','location','sw')

%efficiency 
for Tout = [323.2  326.0  328.8  331.6  334.3 337.1];
I = [500 550 600 650 700 750];
m = 0.02; 
cp = 1009;
Tin = 295;
A = 1.8;
n = m*cp*(Tout - Tin)./A*I
plot(I,n)
end 
ylabel('Efficiency')
xlabel('Epoch')
%latency 
fs = 1.0e4;
t = 0:1/fs:0.005;
signal = cos(2*pi*1000*t)';
shifted_signal = delayseq(signal,5);
figure()
plot(t.*1000,shifted_signal)
ylabel('Latency(msec)')
xlabel('msec')
xlim([0.5 1])
%retransmission
fplot(@(x) exp(x),[-3 0],'b')
hold on
fplot(@(x) cos(x),[0 3],'b')
hold off
grid on
xlabel('Time(msec)')
ylabel('Retransmission(bit/sec)')


