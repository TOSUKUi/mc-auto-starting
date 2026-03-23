import { createInertiaApp } from '@inertiajs/react'
import { MantineProvider } from '@mantine/core'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import AppLayout from '../layouts/AppLayout'
import '@mantine/core/styles.css'

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
        <MantineProvider>
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
