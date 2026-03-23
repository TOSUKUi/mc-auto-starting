import { Code, List, Paper, Stack, Text, ThemeIcon, Title } from '@mantine/core'
import { Head } from '@inertiajs/react'
import { IconCheck } from '@tabler/icons-react'

export default function HomeIndex({ app_name, public_domain, public_port, stack }) {
  return (
    <Stack gap="xl">
      <Head title={app_name} />

      <Stack gap="xs">
        <Title order={1}>{app_name}</Title>
        <Text c="dimmed" size="lg">
          Rails control plane bootstrap is now running on Vite, Inertia, React, and Mantine.
        </Text>
      </Stack>

      <Paper p="xl" radius="md" shadow="sm" withBorder>
        <Stack gap="md">
          <Title order={3}>Current baseline</Title>
          <Text>
            Public Minecraft endpoints will be shown to users as <Code>hostname.{public_domain}:{public_port}</Code>.
          </Text>
          <List
            icon={
              <ThemeIcon color="teal" radius="xl" size={22}>
                <IconCheck size={14} />
              </ThemeIcon>
            }
            spacing="sm"
          >
            {stack.map((item) => (
              <List.Item key={item}>{item}</List.Item>
            ))}
          </List>
        </Stack>
      </Paper>
    </Stack>
  )
}
