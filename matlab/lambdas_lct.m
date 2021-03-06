close all;
clear all; 

rng(0);
scene = 'diffuse_s';
snr = 70;

nlos = loaddata(scene,snr);
w = 64;
h = 64;
d = 512;
measlr = imresize3(nlos.Data,[w,h,d]);
tofgridlr = [];
wall_size = nlos.CameraGridSize;

M = size(measlr,3);
range = M.*nlos.DeltaT;
algorithm = 1;

switch algorithm
  case 0
    alg = 'fbp';
  case 1
    alg = 'lct';
  case 2
    alg = 'f_k';
  case 3
    alg = 'phf';
end

gammas = 4;%2:4;
lambdas = 6;%-8:8;
mse = zeros(1,length(lambdas));
mad = zeros(1,length(lambdas));

posarray = zeros(w,h,1,length(gammas),length(lambdas));
dirarray = zeros(w,h,1,length(gammas),length(lambdas));

for g = 1:length(gammas)
    for l = 1:length(lambdas)
        gamma = gammas(g);
        lambda = lambdas(l);

        tic;
        lct = cnlos_reconstruction(measlr, tofgridlr, wall_size, range, ...
                                   algorithm, 2^lambda, gamma);
        sec = toc;
        [dir,pos] = max(lct,[],3);
        pos = flipud(fliplr(pos'-1)) * ((range/2)/M);
        dir = flipud(fliplr(dir'));

        depth = 0; %fliplr(nlos.Depth');
        depth(isinf(depth)) = NaN;
        
        mse(g,l) = mean(abs(pos(:) - depth(:)).^2,'omitnan');
        mad(g,l) = mean(abs(pos(:) - depth(:)).^1,'omitnan');
        posarray(:,:,:,g,l) = pos;
        dirarray(:,:,:,g,l) = dir;
        
        disp(sprintf('%s %s | SNR: %3f dB, gamma: %d, lambda: %+6.2f, rmse: %5.2e, mad: %5.2e, time: %5.2fs', ...
                 scene, upper(alg), snr, gamma, lambda, sqrt(mse(g,l)), mad(g,l), sec));
    end
end


% save(sprintf('errors_%s_%f_%s.mat',scene,snr,alg),'mse','mad','lambdas','gammas');
% save(sprintf('output_%s_%f_%s.mat',scene,snr,alg),'posarray','dirarray');