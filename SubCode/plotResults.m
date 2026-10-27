function plotResults(R,net,P)
%PLOTRESULTS Individual publication-oriented figures.

n=R.actualRounds;
x=(1:n)';

figure('Name','WSN Topology');
scatter(net.pos(:,1),net.pos(:,2),35,net.energy,'filled'); hold on;
plot(P.BS(:,1),P.BS(:,2),'kp','MarkerSize',14,'MarkerFaceColor','y');
xlabel('X position (m)'); ylabel('Y position (m)');
title('Final Multi-BS WSN Topology'); grid on;

figure('Name','Network Lifetime');
plot(x,R.alive,'LineWidth',1.8);
xlabel('Communication Round'); ylabel('Number of Alive Nodes');
title('Network Lifetime'); grid on;

figure('Name','Dead Nodes');
plot(x,R.dead,'LineWidth',1.8);
xlabel('Communication Round'); ylabel('Number of Dead Nodes');
title('Dead Nodes'); grid on;

figure('Name','Energy');
plot(x,R.energy,'LineWidth',1.8); hold on;
plot(x,R.residualEnergy,'LineWidth',1.8);
xlabel('Communication Round'); ylabel('Energy (J)');
legend('Cumulative Consumed','Residual','Location','best');
title('Energy Behavior'); grid on;

figure('Name','PDR');
plot(x,R.PDR,'LineWidth',1.8);
xlabel('Communication Round'); ylabel('Packet Delivery Ratio'); ylim([0 1.05]);
title('Packet Delivery Ratio'); grid on;

figure('Name','Throughput');
plot(x,R.throughput,'LineWidth',1.8);
xlabel('Communication Round'); ylabel('Throughput (kb/round)');
title('Throughput'); grid on;

figure('Name','Delay');
plot(x,R.delay,'LineWidth',1.8);
xlabel('Communication Round'); ylabel('End-to-End Delay');
title('End-to-End Delay'); grid on;

figure('Name','Routing Reliability');
plot(x,R.reliability,'LineWidth',1.8); hold on;
plot(x,R.loadBalance,'LineWidth',1.8);
plot(x,R.stability,'LineWidth',1.8);
xlabel('Communication Round'); ylabel('Normalized Value');
legend('Routing Reliability','Load Balance','Cluster Stability','Location','best');
title('Routing and Cluster Quality'); grid on;

figure('Name','Loss and Overhead');
plot(x,100*R.packetLoss,'LineWidth',1.8); hold on;
plot(x,100*R.routingOverhead,'LineWidth',1.8);
xlabel('Communication Round'); ylabel('Percentage (%)');
legend('Packet Loss','Routing Overhead','Location','best');
title('Packet Loss and Routing Overhead'); grid on;

figure('Name','Learning');
plot(x,R.reward,'LineWidth',1.6); hold on;
plot(x,R.loss,'LineWidth',1.6);
xlabel('Communication Round'); ylabel('Value');
legend('Average Reward','Local Loss','Location','best');
title('A-AC-PPO Learning Convergence'); grid on;

figure('Name','ADWIN');
stem(x,R.drift,'filled');
xlabel('Communication Round'); ylabel('Drift Detected');
title('ADWIN Drift Events'); grid on;

figure('Name','CH Count');
plot(x,R.numCH,'LineWidth',1.8);
xlabel('Communication Round'); ylabel('Number of CHs');
title('E-MOSSO Cluster Head Selection'); grid on;


figure('Position',[200 150 900 560]);
plot(x, No_Limit, '--o', 'MarkerSize',7);
hold on;
plot(rounds, CH_30, '-s','LineWidth',2, 'MarkerSize',7);
plot(rounds, CH_20,'--^', 'LineWidth',2.5,'MarkerSize',7);
plot(rounds, CH_10, '-d', 'LineWidth',2,'MarkerSize',7);
plot(rounds, CH_5, ':x', 'LineWidth',2, 'MarkerSize',8);
xlabel('Communication Rounds','FontSize',13, 'FontWeight','bold');
ylabel('Throughput (kbps)', 'FontSize',13, 'FontWeight','bold');
title('Throughput vs. Rounds for Different CH Limits', 'FontSize',14, 'FontWeight','bold');
legend('No Limit','30% CH', '20% CH', '10% CH','5% CH', 'Location','northwest');
grid on;
box on;

set(gca,'FontSize',11);
text(1050,82.5,'Proposed FedDRL-DA-MOO (E-MOSSO)','FontSize',10,'FontWeight','bold', ...
    'BackgroundColor','white', ...
    'EdgeColor','black');


figure;
plot(rounds,NoLimit_Energy,'--o','LineWidth',2); hold on;
plot(rounds,CH30_Energy,'-s','LineWidth',2);
plot(rounds,CH20_Energy,'--^','LineWidth',2.5);
plot(rounds,CH10_Energy,'-d','LineWidth',2);
plot(rounds,CH5_Energy,':x','LineWidth',2);
xlabel('Communication Rounds');
ylabel('Energy Consumption (J)');
title('Energy Consumption vs. Rounds for Different CH Limits');
legend(labels,'Location','northwest');
grid on; box on;


figure;
plot(rounds,NoLimit_Alive,'--o','LineWidth',2); hold on;
plot(rounds,CH30_Alive,'-s','LineWidth',2);
plot(rounds,CH20_Alive,'--^','LineWidth',2.5);
plot(rounds,CH10_Alive,'-d','LineWidth',2);
plot(rounds,CH5_Alive,':x','LineWidth',2);
xlabel('Communication Rounds');
ylabel('Number of Alive Nodes');
title('Network Lifetime vs. Rounds for Different CH Limits');
legend(labels,'Location','southwest');
ylim([0 105]);
grid on; box on;

figure;
plot(rounds,NoLimit_PDR,'--o','LineWidth',2); hold on;
plot(rounds,CH30_PDR,'-s','LineWidth',2);
plot(rounds,CH20_PDR,'--^','LineWidth',2.5);
plot(rounds,CH10_PDR,'-d','LineWidth',2);
plot(rounds,CH5_PDR,':x','LineWidth',2);
xlabel('Communication Rounds');
ylabel('Packet Delivery Ratio');
title('PDR vs. Rounds for Different CH Limits');
legend(labels,'Location','southwest');
ylim([0.5 1]);
grid on; box on;

figure;
plot(rounds,NoLimit_Thr,'--o','LineWidth',2); hold on;
plot(rounds,CH30_Thr,'-s','LineWidth',2);
plot(rounds,CH20_Thr,'--^','LineWidth',2.5);
plot(rounds,CH10_Thr,'-d','LineWidth',2);
plot(rounds,CH5_Thr,':x','LineWidth',2);
xlabel('Communication Rounds');
ylabel('Throughput (kbps)');
title('Throughput vs. Rounds for Different CH Limits');
legend(labels,'Location','northwest');
grid on; box on;

figure;
plot(rounds,NoLimit_Delay,'--o','LineWidth',2); hold on;
plot(rounds,CH30_Delay,'-s','LineWidth',2);
plot(rounds,CH20_Delay,'--^','LineWidth',2.5);
plot(rounds,CH10_Delay,'-d','LineWidth',2);
plot(rounds,CH5_Delay,':x','LineWidth',2);
xlabel('Communication Rounds');
ylabel('End-to-End Delay (ms)');
title('End-to-End Delay vs. Rounds for Different CH Limits');
legend(labels,'Location','northwest');
grid on; box on;

figure;
plot(rounds,NoLimit_Overhead,'--o','LineWidth',2); hold on;
plot(rounds,CH30_Overhead,'-s','LineWidth',2);
plot(rounds,CH20_Overhead,'--^','LineWidth',2.5);
plot(rounds,CH10_Overhead,'-d','LineWidth',2);
plot(rounds,CH5_Overhead,':x','LineWidth',2);
xlabel('Communication Rounds');
ylabel('Routing Overhead (%)');
title('Routing Overhead vs. Rounds for Different CH Limits');
legend(labels,'Location','northwest');
grid on; box on;

figure;
plot(rounds,NoLimit_Loss,'--o','LineWidth',2); hold on;
plot(rounds,CH30_Loss,'-s','LineWidth',2);
plot(rounds,CH20_Loss,'--^','LineWidth',2.5);
plot(rounds,CH10_Loss,'-d','LineWidth',2);
plot(rounds,CH5_Loss,':x','LineWidth',2);
xlabel('Communication Rounds');
ylabel('Packet Loss (%)');
title('Packet Loss vs. Rounds for Different CH Limits');
legend(labels,'Location','northwest');
grid on; box on;

figure;
plot(rounds,NoLimit_Stability,'--o','LineWidth',2); hold on;
plot(rounds,CH30_Stability,'-s','LineWidth',2);
plot(rounds,CH20_Stability,'--^','LineWidth',2.5);
plot(rounds,CH10_Stability,'-d','LineWidth',2);
plot(rounds,CH5_Stability,':x','LineWidth',2);
xlabel('Communication Rounds');
ylabel('Cluster Stability');
title('Cluster Stability vs. Rounds for Different CH Limits');
legend(labels,'Location','southwest');
ylim([0.4 1]);
grid on; box on;

figure;
plot(rounds,NoLimit_Dead,'--o','LineWidth',2); hold on;
plot(rounds,CH30_Dead,'-s','LineWidth',2);
plot(rounds,CH20_Dead,'--^','LineWidth',2.5);
plot(rounds,CH10_Dead,'-d','LineWidth',2);
plot(rounds,CH5_Dead,':x','LineWidth',2);
xlabel('Communication Rounds');
ylabel('Number of Dead Nodes');
title('Dead Nodes vs. Rounds for Different CH Limits');
legend(labels,'Location','northwest');
ylim([0 100]);
grid on; box on;

figure;
plot(rounds,NoLimit_Reward,'--o','LineWidth',2); hold on;
plot(rounds,CH30_Reward,'-s','LineWidth',2);
plot(rounds,CH20_Reward,'--^','LineWidth',2.5);
plot(rounds,CH10_Reward,'-d','LineWidth',2);
plot(rounds,CH5_Reward,':x','LineWidth',2);
xlabel('Communication Rounds');
ylabel('Average Reward');
title('Learning Convergence vs. Rounds for Different CH Limits');
legend(labels,'Location','southeast');
ylim([0.2 1]);
grid on; box on;


end
