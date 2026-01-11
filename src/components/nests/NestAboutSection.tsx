interface Props {
  about: string;
}

const NestAboutSection = ({ about }: Props) => (
  <div className="card p-6">
    <h3 className="text-lg font-semibold text-sparrow-navy mb-2">About the fund</h3>
    <p className="text-sm text-sparrow-navy/80 leading-6">{about}</p>
  </div>
);

export default NestAboutSection;
