import { Layout } from 'antd';

export default function Footer() {
  return (
    <Layout.Footer className="flex items-center bg-neutral-200 text-white px-6 pt-8">
      <div className="w-full text-neutral-800 text-right">
        <p className="m-0 px-2">
          © 2025 Hanyang University DDPS Lab. All Rights Reserved.
        </p>
        <div className="bg-white p-2 px-4 mt-3 rounded-sm flex gap-2 justify-between">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            className="size-4"
            fill="none"
            viewBox="0 0 511 509"
          >
            <path
              fill="#2F7DB6"
              d="M17.6983 16.4224c-21.15681 21.1568-21.15681 55.4624 0 76.6192.2471.2472.4943.4695.7167.692h-.0247L159.098 234.466l76.644-76.644L95.0343 17.1144c-.2225-.2472-.4696-.4943-.6921-.7168-21.1568-21.15677-55.4624-21.15677-76.6192 0"
            />
            <path
              fill="#00477F"
              d="M56.2058 508.442c-26.3471-.075-48.86329-18.958-53.5593-44.885L.916382 454.61v-22.145L109.988 323.344.916382 432.415V301.1h.395458l-.09886-94.242-.17302-88.977L109.839 226.68v74.42h.173v22.244l19.501-19.476L416.366 16.9663l.123.0494c.173-.2225.396-.3955.569-.6179 21.305-21.30513 55.857-21.30513 77.138 0 21.305 21.305 21.305 55.8579 0 77.1383-.717.6673-1.458 1.384-2.175 2.0513L94.8862 492.722l-.1731-.099c-7.8102 7.786-17.8201 12.976-28.6951 14.904-3.1636.569-6.3767.865-9.5898.89h-.2224v.025Z"
            />
            <path
              fill="#2F7DB6"
              d="M416.069 491.709c-1.112-1.063-2.101-2.224-3.09-3.386L277.363 352.732l76.619-76.595 46.046 45.996 109.047 109.121v19.204c1.532 30.055-21.577 55.66-51.657 57.193-15.422.791-30.45-4.993-41.349-15.917v-.025Zm-16.066-169.6v-92.042l.173-.173h.297l108.898-108.429-.296 134.949v174.815l-109.047-109.12h-.025Z"
            />
          </svg>
          <p className="m-0 flex-1 text-left">
            An official web-service of the Hanyang University{' '}
            <a href="https://ddps.cloud">DDPS Lab.</a>
          </p>
        </div>
      </div>
    </Layout.Footer>
  );
}
