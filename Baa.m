clear;clc;close all;fclose all;
load ('Baa.mat','baa')
soundobj = audioplayer(baa,44100);
play(soundobj);

