import { useState, useEffect, useMemo } from 'react';
import dynamic from 'next/dynamic';
import { mfApi, NavDataPoint } from '@/services/api';

const ReactECharts = dynamic(() => import('echarts-for-react'), { ssr: false });

// FA Portal Color Palette - Main Design (Blue/Cyan)
const FA_COLORS_LIGHT = {
  primary: '#3B82F6',
  primaryDark: '#2563EB',
  secondary: '#38BDF8',
  success: '#10B981',
  error: '#EF4444',
  textPrimary: '#1E293B',
  textSecondary: '#64748B',
  textTertiary: '#94A3B8',
  chipBg: 'rgba(59, 130, 246, 0.04)',
  chipBorder: 'rgba(59, 130, 246, 0.1)',
  cardBorder: 'rgba(59, 130, 246, 0.08)',
};

const FA_COLORS_DARK = {
  primary: '#93C5FD',
  primaryDark: '#60A5FA',
  secondary: '#7DD3FC',
  success: '#34D399',
  error: '#F87171',
  textPrimary: '#F8FAFC',
  textSecondary: '#E2E8F0',
  textTertiary: '#94A3B8',
  chipBg: 'rgba(147, 197, 253, 0.06)',
  chipBorder: 'rgba(147, 197, 253, 0.12)',
  cardBorder: 'rgba(147, 197, 253, 0.12)',
};

type Period = '1M' | '6M' | '1Y' | '3Y' | '5Y';

interface FundNavChartProps {
  schemeCode: number;
  isDark?: boolean;
}

// Parse DD-MM-YYYY date string to Date object
const parseDate = (dateStr: string): Date => {
  const [day, month, year] = dateStr.split('-').map(Number);
  return new Date(year, month - 1, day);
};

// Format date for display
const formatDate = (dateStr: string): string => {
  const date = parseDate(dateStr);
  return date.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: '2-digit' });
};

// Filter data by period
const filterByPeriod = (data: NavDataPoint[], period: Period): NavDataPoint[] => {
  if (!data.length) return [];

  const now = new Date();
  let cutoffDate: Date;

  switch (period) {
    case '1M':
      cutoffDate = new Date(now.setMonth(now.getMonth() - 1));
      break;
    case '6M':
      cutoffDate = new Date(now.setMonth(now.getMonth() - 6));
      break;
    case '1Y':
      cutoffDate = new Date(now.setFullYear(now.getFullYear() - 1));
      break;
    case '3Y':
      cutoffDate = new Date(now.setFullYear(now.getFullYear() - 3));
      break;
    case '5Y':
      cutoffDate = new Date(now.setFullYear(now.getFullYear() - 5));
      break;
    default:
      cutoffDate = new Date(now.setFullYear(now.getFullYear() - 1));
  }

  return data.filter(point => parseDate(point.date) >= cutoffDate);
};

export default function FundNavChart({ schemeCode, isDark = false }: FundNavChartProps) {
  const [navData, setNavData] = useState<NavDataPoint[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [period, setPeriod] = useState<Period>('1Y');

  const colors = isDark ? FA_COLORS_DARK : FA_COLORS_LIGHT;
  const periods: Period[] = ['1M', '6M', '1Y', '3Y', '5Y'];

  useEffect(() => {
    const loadNavHistory = async () => {
      try {
        setLoading(true);
        setError(null);
        const response = await mfApi.getNavHistory(schemeCode);
        // Data comes in reverse chronological order, so we reverse it
        setNavData(response.data.reverse());
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load NAV history');
      } finally {
        setLoading(false);
      }
    };
    loadNavHistory();
  }, [schemeCode]);

  const filteredData = useMemo(() => filterByPeriod(navData, period), [navData, period]);

  // Calculate returns for the period
  const periodReturn = useMemo(() => {
    if (filteredData.length < 2) return null;
    const startNav = parseFloat(filteredData[0].nav);
    const endNav = parseFloat(filteredData[filteredData.length - 1].nav);
    return ((endNav - startNav) / startNav * 100);
  }, [filteredData]);

  const chartOption = useMemo(() => {
    if (!filteredData.length) return {};

    const dates = filteredData.map(d => formatDate(d.date));
    const navs = filteredData.map(d => parseFloat(d.nav));

    // Dark mode specific colors
    const bgColor = isDark ? 'transparent' : '#FFFFFF';
    const tooltipBg = isDark ? '#1E293B' : '#FFFFFF';
    const tooltipBorder = isDark ? 'rgba(147, 197, 253, 0.2)' : 'rgba(59, 130, 246, 0.15)';
    const tooltipTextColor = isDark ? '#F8FAFC' : '#1E293B';
    const tooltipSecondaryColor = isDark ? '#94A3B8' : '#64748B';
    const axisLineColor = isDark ? 'rgba(147, 197, 253, 0.15)' : 'rgba(59, 130, 246, 0.08)';
    const axisLabelColor = isDark ? '#94A3B8' : '#64748B';
    const splitLineColor = isDark ? 'rgba(147, 197, 253, 0.1)' : 'rgba(59, 130, 246, 0.06)';
    const lineColors = isDark
      ? [
          { offset: 0, color: '#93C5FD' },
          { offset: 0.5, color: '#60A5FA' },
          { offset: 1, color: '#7DD3FC' },
        ]
      : [
          { offset: 0, color: '#3B82F6' },
          { offset: 0.5, color: '#2563EB' },
          { offset: 1, color: '#38BDF8' },
        ];
    const areaColors = isDark
      ? [
          { offset: 0, color: 'rgba(147, 197, 253, 0.15)' },
          { offset: 0.5, color: 'rgba(147, 197, 253, 0.05)' },
          { offset: 1, color: 'rgba(147, 197, 253, 0)' },
        ]
      : [
          { offset: 0, color: 'rgba(59, 130, 246, 0.12)' },
          { offset: 0.5, color: 'rgba(59, 130, 246, 0.04)' },
          { offset: 1, color: 'rgba(59, 130, 246, 0)' },
        ];

    return {
      backgroundColor: bgColor,
      tooltip: {
        trigger: 'axis',
        backgroundColor: tooltipBg,
        borderColor: tooltipBorder,
        borderWidth: 1,
        padding: [12, 16],
        textStyle: { color: tooltipTextColor, fontSize: 13 },
        formatter: (params: any) => {
          const data = params[0];
          return `
            <div style="font-weight: 600; margin-bottom: 4px; color: ${tooltipTextColor};">${data.name}</div>
            <div style="color: ${tooltipSecondaryColor}">NAV: <span style="color: ${colors.primary}; font-weight: 600;">${parseFloat(data.value).toFixed(4)}</span></div>
          `;
        },
      },
      grid: {
        left: 50,
        right: 20,
        top: 20,
        bottom: 40,
      },
      xAxis: {
        type: 'category',
        data: dates,
        boundaryGap: false,
        axisLine: { lineStyle: { color: axisLineColor } },
        axisTick: { show: false },
        axisLabel: {
          color: axisLabelColor,
          fontSize: 11,
          interval: Math.floor(dates.length / 6),
        },
        splitLine: { show: false },
      },
      yAxis: {
        type: 'value',
        min: (value: { min: number }) => (value.min * 0.98).toFixed(2),
        max: (value: { max: number }) => (value.max * 1.02).toFixed(2),
        axisLine: { show: false },
        axisTick: { show: false },
        splitLine: {
          lineStyle: {
            color: splitLineColor,
            type: 'dashed',
          },
        },
        axisLabel: {
          color: axisLabelColor,
          fontSize: 11,
          formatter: (value: number) => value.toFixed(0),
        },
      },
      series: [
        {
          data: navs,
          type: 'line',
          smooth: true,
          symbol: 'circle',
          symbolSize: 8,
          showSymbol: false,
          lineStyle: {
            width: 3,
            color: {
              type: 'linear',
              x: 0,
              y: 0,
              x2: 1,
              y2: 0,
              colorStops: lineColors,
            },
            shadowColor: isDark ? 'rgba(147, 197, 253, 0.3)' : 'rgba(59, 130, 246, 0.25)',
            shadowBlur: 10,
            shadowOffsetY: 5,
          },
          itemStyle: {
            color: colors.primary,
            borderWidth: 2,
            borderColor: isDark ? '#1E293B' : '#FFFFFF',
          },
          areaStyle: {
            color: {
              type: 'linear',
              x: 0,
              y: 0,
              x2: 0,
              y2: 1,
              colorStops: areaColors,
            },
          },
          emphasis: {
            focus: 'series',
            itemStyle: {
              shadowBlur: 15,
              shadowColor: isDark ? 'rgba(147, 197, 253, 0.5)' : 'rgba(59, 130, 246, 0.4)',
            },
          },
        },
      ],
    };
  }, [filteredData, isDark, colors]);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <svg className="w-8 h-8 animate-spin" style={{ color: colors.primary }} fill="none" viewBox="0 0 24 24">
          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
        </svg>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center h-64">
        <svg className="w-12 h-12 mb-4" style={{ color: colors.error }} fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
        </svg>
        <p className="text-sm" style={{ color: colors.textSecondary }}>{error}</p>
      </div>
    );
  }

  return (
    <div>
      {/* Period Selector */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-2">
          {periodReturn !== null && (
            <span
              className="text-sm font-semibold px-3 py-1 rounded-full"
              style={{
                background: periodReturn >= 0 ? `${colors.success}15` : `${colors.error}15`,
                color: periodReturn >= 0 ? colors.success : colors.error,
              }}
            >
              {periodReturn >= 0 ? '+' : ''}{periodReturn.toFixed(2)}%
            </span>
          )}
          <span className="text-xs" style={{ color: colors.textTertiary }}>
            {period} return
          </span>
        </div>
        <div className="flex gap-1 p-1 rounded-lg" style={{ background: colors.chipBg }}>
          {periods.map(p => (
            <button
              key={p}
              onClick={() => setPeriod(p)}
              className="px-3 py-1.5 rounded-md text-xs font-medium transition-all"
              style={{
                background: period === p
                  ? `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`
                  : 'transparent',
                color: period === p ? 'white' : colors.textSecondary,
              }}
            >
              {p}
            </button>
          ))}
        </div>
      </div>

      {/* Chart */}
      {filteredData.length > 0 ? (
        <ReactECharts
          option={chartOption}
          style={{ height: 280 }}
          opts={{ renderer: 'svg' }}
        />
      ) : (
        <div className="flex items-center justify-center h-64">
          <p className="text-sm" style={{ color: colors.textTertiary }}>
            No data available for this period
          </p>
        </div>
      )}
    </div>
  );
}
