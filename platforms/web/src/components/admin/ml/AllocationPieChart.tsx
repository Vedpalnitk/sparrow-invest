/**
 * Allocation Pie Chart Component - Admin Portal
 *
 * Donut chart visualization for blended allocation breakdown.
 * Uses ECharts with dynamic import to avoid SSR issues.
 */

import { useMemo } from 'react';
import dynamic from 'next/dynamic';
import { useAdminTheme } from '@/utils/adminTheme';
import { AllocationBreakdown } from '@/services/api';

const ReactECharts = dynamic(() => import('echarts-for-react'), { ssr: false });

interface AllocationPieChartProps {
  allocation: AllocationBreakdown;
  height?: number;
  showLegend?: boolean;
}

// Asset class color mapping
const getAssetClassColor = (assetClass: string, isDark: boolean): string => {
  const colors: Record<string, { light: string; dark: string }> = {
    equity: { light: '#3B82F6', dark: '#60A5FA' },
    debt: { light: '#10B981', dark: '#34D399' },
    hybrid: { light: '#8B5CF6', dark: '#A78BFA' },
    gold: { light: '#F59E0B', dark: '#FBBF24' },
    international: { light: '#EC4899', dark: '#F472B6' },
    liquid: { light: '#06B6D4', dark: '#22D3EE' },
  };
  return colors[assetClass]?.[isDark ? 'dark' : 'light'] || '#94A3B8';
};

export const AllocationPieChart = ({
  allocation,
  height = 280,
  showLegend = true,
}: AllocationPieChartProps) => {
  const { colors, isDark } = useAdminTheme();

  const chartData = useMemo(() => {
    const entries = Object.entries(allocation)
      .filter(([_, value]) => value > 0)
      .map(([key, value]) => ({
        name: key.charAt(0).toUpperCase() + key.slice(1),
        value: value,
        itemStyle: {
          color: getAssetClassColor(key, isDark),
        },
      }));
    return entries;
  }, [allocation, isDark]);

  const chartOption = useMemo(() => {
    return {
      backgroundColor: 'transparent',
      tooltip: {
        trigger: 'item',
        backgroundColor: isDark ? '#1E293B' : '#FFFFFF',
        borderColor: colors.cardBorder,
        borderWidth: 1,
        padding: [12, 16],
        textStyle: { color: colors.textPrimary, fontSize: 13 },
        formatter: (params: any) => {
          return `
            <div style="display: flex; align-items: center; gap: 8px;">
              <div style="width: 10px; height: 10px; border-radius: 50%; background: ${params.color};"></div>
              <span style="font-weight: 600;">${params.name}</span>
            </div>
            <div style="margin-top: 4px; color: ${colors.textSecondary};">
              ${params.value.toFixed(1)}%
            </div>
          `;
        },
      },
      legend: showLegend
        ? {
            orient: 'vertical',
            right: 10,
            top: 'center',
            itemWidth: 12,
            itemHeight: 12,
            itemGap: 12,
            textStyle: {
              color: colors.textSecondary,
              fontSize: 12,
            },
            formatter: (name: string) => {
              const item = chartData.find((d) => d.name === name);
              return `${name}  ${item?.value.toFixed(1)}%`;
            },
          }
        : undefined,
      series: [
        {
          name: 'Allocation',
          type: 'pie',
          radius: ['55%', '80%'],
          center: showLegend ? ['35%', '50%'] : ['50%', '50%'],
          avoidLabelOverlap: false,
          itemStyle: {
            borderRadius: 6,
            borderColor: isDark ? '#0B1120' : '#FFFFFF',
            borderWidth: 3,
          },
          label: {
            show: false,
          },
          emphasis: {
            label: {
              show: true,
              fontSize: 14,
              fontWeight: 'bold',
              color: colors.textPrimary,
              formatter: '{b}\n{d}%',
            },
            itemStyle: {
              shadowBlur: 20,
              shadowOffsetX: 0,
              shadowColor: 'rgba(0, 0, 0, 0.2)',
            },
          },
          labelLine: {
            show: false,
          },
          data: chartData,
        },
      ],
    };
  }, [chartData, colors, isDark, showLegend]);

  if (chartData.length === 0) {
    return (
      <div
        className="flex items-center justify-center"
        style={{ height, color: colors.textTertiary }}
      >
        <p className="text-sm">No allocation data</p>
      </div>
    );
  }

  return (
    <ReactECharts
      option={chartOption}
      style={{ height }}
      opts={{ renderer: 'svg' }}
    />
  );
};

export default AllocationPieChart;
