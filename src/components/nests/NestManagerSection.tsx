interface Props {
  name: string;
  description: string;
}

const NestManagerSection = ({ name, description }: Props) => (
  <div className="card p-6">
    <div className="flex items-center gap-3">
      <div className="w-12 h-12 rounded-full bg-gradient-to-br from-sparrow-gradientStart to-sparrow-gradientEnd text-white font-semibold flex items-center justify-center">
        {name.slice(0, 1)}
      </div>
      <div>
        <p className="text-sm uppercase text-sparrow-navy/60">Fund manager</p>
        <p className="text-lg font-semibold text-sparrow-navy">{name}</p>
        <p className="text-sm text-sparrow-navy/70 mt-1">{description}</p>
      </div>
    </div>
  </div>
);

export default NestManagerSection;
