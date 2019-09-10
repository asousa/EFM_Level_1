close all; clear all;
% Compare vs backyard corrections:
EFMs = containers.Map;
EFMs("Cordoba") = "EFM011";
EFMs("Manfredi") = "EFM004";
EFMs("Pilar") = "EFM006";
EFMs("Villa-del-Rosario") = "EFM002";
EFMs("Villa-Carlos-Paz") = "EFM008";

% % Just typed in from running between 6/18 - 6/24.
% % EFM006 used absolute field values, everything else normal.
backyard_gains = containers.Map;
backyard_offsets = containers.Map;
% backyard_gains("EFM002") = 0.0436; backyard_offsets("EFM002") = -0.9096;
% backyard_gains("EFM006") = 0.0407; backyard_offsets("EFM006") = 18.7037;
% backyard_gains("EFM008") = 0.0586; backyard_offsets("EFM008") = 14.7467;
% backyard_gains("EFM011") = 0.1062; backyard_offsets("EFM011") = 83.8318;

% These are with Csite = 1.0: e.g., to match backyard data to the campbell
% at the setup height, but not to map to the true electric field (dependent
% on Campbell correction)
backyard_gains("EFM002") = 0.4262; backyard_offsets("EFM002") = -5.7975;
backyard_gains("EFM006") = 0.3915; backyard_offsets("EFM006") = 177.1194;
backyard_gains("EFM008") = 0.5625; backyard_offsets("EFM008") = 142.4066;
backyard_gains("EFM011") = 1.0117; backyard_offsets("EFM011") = 798.3978;
Csite = 0.233;  % Taken from Austin's backyard test data, 7/18/2019

site_gains = containers.Map;
site_offsets = containers.Map;
% site_gains("Cordoba") = 0.0222;           site_offsets("Cordoba") = 25.3092;
% site_gains("Manfredi") = 0.0427;          site_offsets("Manfredi") = 0;
% site_gains("Pilar") = 0.0576;             site_offsets("Pilar") = 13.8439;
% site_gains("Villa-Carlos-Paz") = 0.0458;  site_offsets("Villa-Carlos-Paz") = 10.4258;
% site_gains("Villa-del-Rosario") = 0.0200; site_offsets("Villa-del-Rosario") = -1.9374;

% These are computed using Argentina field calibrations, with Csite=0.233
site_gains("Cordoba") = 0.0559;           site_offsets("Cordoba") = 50.5869;
site_gains("Manfredi") = 0.1629;          site_offsets("Manfredi") = 0;
site_gains("Pilar") = 0.1277;             site_offsets("Pilar") = 10.7203;
site_gains("Villa-Carlos-Paz") = 0.1207;  site_offsets("Villa-Carlos-Paz") = 14.2689;
site_gains("Villa-del-Rosario") = 0.0446; site_offsets("Villa-del-Rosario") = -24.2991;

rel_err = 0.2;

sites = ["Cordoba","Manfredi","Pilar","Villa-Carlos-Paz","Villa-del-Rosario"];
site_labels = ["Cordoba","Manfredi","Pilar","VCP","VDR"];

    
set(groot,'defaultfigurecolor',[1 1 1])
set(groot,'defaultAxesFontSize',16)
set(groot,'defaultTextFontSize',18)
set(groot,'defaultAxesFontWeight','bold');
set(groot,'defaultTextFontWeight','bold');
set(groot,'defaultAxesLineWidth',2);
set(groot,'defaultUicontrolFontName','Arial');
set(groot,'defaultUitableFontName','Arial');
set(groot,'defaultAxesFontName','Arial');
set(groot,'defaultTextFontName','Arial');
set(groot,'defaultUipanelFontName','Arial');


    fig = figure('units','inch','position',[0,0,10,8]);
% fig = figure('units','pixels','position',[0 0 1280 720]);
axs = tight_subplot(2,1,0.03, 0.8/10, 0.8/8);
hold(axs(1),'on');
box(axs(1),'on');
hold(axs(2),'on');
box(axs(2),'on');


for s=1:length(sites)
   site = sites(s);
   EFM = EFMs(site);
   gain = site_gains(site);
   gup = gain*(1 + rel_err);
   gdn = gain*(1 - rel_err);
   w = 0.2;
   plot(axs(1),[s - w,s + w],[gain, gain],'k','LineWidth',2);
   hold on;
   h1=fill(axs(1),[s-w,s-w, s+w, s+w],[gdn,gup,gup,gdn],'red','FaceAlpha',0.1);
  plot(axs(1),s,gain,'ko');

   if backyard_gains.isKey(EFM)
       gain = backyard_gains(EFM)*Csite;
       gup = gain*(1 + rel_err);
       gdn = gain*(1 - rel_err);

       plot(axs(1),[s - w,s + w],[gain, gain],'k','LineWidth',2);
       plot(axs(1),s,gain,'ko');
       h2=fill(axs(1),[s-w,s-w, s+w, s+w],[gdn,gup,gup,gdn],'blue','FaceAlpha',0.1);
       grid(axs(1),'on');
   end
   
   xticks(axs(1),1:length(sites));
   xticklabels(axs(1),[]);
%       set(axs(1),'yscale','log');

   ylabel(axs(1),'Gain');
   yticks(axs(1),'auto');
   yticklabels(axs(1),'auto');

end

legend(axs(1),[h1,h2],'Argentina','Colorado');
text(axs(1),3,0.01, "Boxes denote ± 20%",'FontSize',14);



for s=1:length(sites)
   site = sites(s);
   EFM = EFMs(site);
   offset = site_offsets(site);
   oup = offset*(1 + rel_err);
   odn = offset*(1 - rel_err);
   w = 0.2;
   plot(axs(2),[s - w,s + w],[offset, offset],'k','LineWidth',2);
   plot(axs(2),s,offset,'ko');

   hold on;
   h1=fill(axs(2),[s-w,s-w, s+w, s+w],[odn,oup,oup,odn],'red','FaceAlpha',0.1,'LineWidth',1);
   if backyard_offsets.isKey(EFM)
       offset = backyard_offsets(EFM)*Csite;
       oup = offset*(1 + rel_err);
       odn = offset*(1 - rel_err);

       plot(axs(2),[s - w,s + w],[offset, offset],'k','LineWidth',2);
       plot(axs(2),s,offset,'ko');

       hold on;
       h2=fill(axs(2),[s-w,s-w, s+w, s+w],[odn,oup,oup,odn],'blue','FaceAlpha',0.1,'LineWidth',1);
       grid(axs(2),'on');
   end
   
   xticks(1:length(sites));
   xticklabels(site_labels);
   yticks(axs(2),'auto');
   grid on;
   ylabel('Offset (V/m)');  
   yticklabels(axs(2),'auto');

end

legend(axs(2),[h1,h2],'Argentina','Colorado');

linkaxes(axs,'x');

sgtitle("Site Correction Comparison, July 2019")
saveas(fig,"Site correction comparison July 2019.png");


