import { createInertiaApp } from '@inertiajs/react'
import { MantineProvider } from '@mantine/core'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import AppLayout from '../layouts/AppLayout'
import '@mantine/core/styles.css'

const minecraftTheme = {
  primaryColor: 'grass',
  defaultRadius: 'md',
  colors: {
    grass: [
      '#edf8e6',
      '#d8efc9',
      '#b6df99',
      '#94cf6d',
      '#76bf45',
      '#63b02f',
      '#559a24',
      '#44791d',
      '#355a16',
      '#253f0f',
    ],
    dirt: [
      '#f6eee7',
      '#e8d7c8',
      '#d5b79e',
      '#c29472',
      '#b0774c',
      '#a16439',
      '#8d532e',
      '#6f4125',
      '#51301b',
      '#381f11',
    ],
    stone: [
      '#f1f2f2',
      '#dde0df',
      '#c0c5c3',
      '#a2aaa7',
      '#88918d',
      '#737b78',
      '#636965',
      '#4e534f',
      '#383c39',
      '#232624',
    ],
  },
  components: {
    Paper: {
      defaultProps: {
        bg: '#23211d',
        c: '#f1efe8',
      },
    },
    Button: {
      defaultProps: {
        color: 'grass',
      },
    },
  },
}

createInertiaApp({
  // Set default page title
  // see https://inertia-rails.dev/guide/title-and-meta
  //
  // title: title => title ? `${title} - App` : 'App',

  // Disable progress bar
  //
  // see https://inertia-rails.dev/guide/progress-indicators
  // progress: false,

  resolve: (name) => {
    const pages = import.meta.glob('../pages/**/*.jsx', {
      eager: true,
    })
    const page = pages[`../pages/${name}.jsx`]
    if (!page) {
      console.error(`Missing Inertia page component: '${name}.jsx'`)
    }

    page.default.layout ||= (page) => <AppLayout>{page}</AppLayout>

    return page
  },

  setup({ el, App, props }) {
    createRoot(el).render(
      <StrictMode>
        <MantineProvider forceColorScheme="dark" theme={minecraftTheme}>
          <App {...props} />
        </MantineProvider>
      </StrictMode>
    )
  },

  defaults: {
    form: {
      forceIndicesArrayFormatInFormData: false,
      withAllErrors: true,
    },
    future: {
      useScriptElementForInitialPage: true,
      useDataInertiaHeadAttribute: true,
      useDialogForErrorModal: true,
      preserveEqualProps: true,
    },
  },
}).catch((error) => {
  // This ensures this entrypoint is only loaded on Inertia pages
  // by checking for the presence of the root element (#app by default).
  // Feel free to remove this `catch` if you don't need it.
  if (document.getElementById("app")) {
    throw error
  } else {
    console.error(
      "Missing root element.\n\n" +
      "If you see this error, it probably means you loaded Inertia.js on non-Inertia pages.\n" +
      'Consider moving <%= vite_javascript_tag "inertia.jsx" %> to the Inertia-specific layout instead.',
    )
  }
})
