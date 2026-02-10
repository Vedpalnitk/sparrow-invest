/**
 * Risk Gauge Chart Component - Admin Portal
 *
 * Gauge visualization for risk score display.
 * Uses ECharts with dynamic import to avoid SSR issues.
 */

import { useMemo } from 'react';
import dynamic from 'next/dynamic';
import { useAdminTheme } from '@/utils/adminTheme';

const ReactECharts = dynamic(() => import('echarts-for-react'), { ssr: false });

interface RiskGaugeChartProps {
  score: number; // 0-100
  riskLevel?: string;
  height?: number;
}

export const RiskGaugeChart = ({
  score,
  riskLevel,
  height = 200,
}: RiskGaugeChartProps) => {
  const { colors, isDark } = useAdminTheme();

  // Get color based on risk score
  const getRiskColor = (value: number): string => {
    if (value <= 30) return isDark ? '#34D399' : '#10B981'; // Low - Green
    if (value <= 60) return isDark ? '#FBBF24' : '#F59E0B'; // Medium - Yellow
    return isDark ? '#F87171' : '#EF4444'; // High - Red
  };

  const chartOption = useMemo(() => {
    const riskColor = getRiskColor(score);

    return {
      backgroundColor: 'transparent',
      series: [
        {
          type: 'gauge',
          startAngle: 180,
          endAngle: 0,
          center: ['50%', '70%'],
          radius: '100%',
          min: 0,
          max: 100,
          splitNumber: 4,
          axisLine: {
            lineStyle: {
              width: 20,
              color: [
                [0.3, isDark ? '#34D399' : '#10B981'],
                [0.6, isDark ? '#FBBF24' : '#F59E0B'],
                [1, isDark ? '#F87171' : '#EF4444'],
              ],
            },
          },
          pointer: {
            icon: 'path://M12.8,0.7l12,40.1H0.7L12.8,0.7z',
            length: '60%',
            width: 10,
            offsetCenter: [0, '-10%'],
            itemStyle: {
              color: riskColor,
              shadowColor: `${riskColor}40`,
              shadowBlur: 10,
            },
          },
          axisTick: {
            length: 8,
            lineStyle: {
              color: 'auto',
              width: 2,
            },
          },
          splitLine: {
            length: 12,
            lineStyle: {
              color: 'auto',
              width: 3,
            },
          },
          axisLabel: {
            color: colors.textTertiary,
            fontSize: 11,
            distance: -40,
            formatter: (value: number) => {
              if (value === 0) return 'Low';
              if (value === 50) return 'Med';
              if (value === 100) return 'High';
              return '';
            },
          },
          title: {
            offsetCenter: [0, '20%'],
            fontSize: 12,
            color: colors.textSecondary,
          },
          detail: {
            fontSize: 28,
            offsetCenter: [0, '-25%'],
            valueAnimation: true,
            formatter: (value: number) => value.toFixed(0),
            color: riskColor,
            fontWeight: 'bold',
          },
          data: [
            {
              value: score,
              name: riskLevel || '',
            },
          ],
        },
      ],
    };
  }, [score, riskLevel, colors, isDark]);

  return (
    <div className="relative">
      <ReactECharts
        option={chartOption}
        style={{ height }}
        opts={{ renderer: 'svg' }}
      />
      {/* Risk level label below gauge */}
      {riskLevel && (
        <div
          className="absolute bottom-0 left-1/2 transform -translate-x-1/2 text-center"
          style={{ marginBottom: -10 }}
        >
          <span
            className="text-xs font-semibold px-3 py-1 rounded-full"
            style={{
              background: `${getRiskColor(score)}15`,
              color: getRiskColor(score),
            }}
          >
            {riskLevel}
          </span>
        </div>
      )}
    </div>
  );
};

export default RiskGaugeChart;
