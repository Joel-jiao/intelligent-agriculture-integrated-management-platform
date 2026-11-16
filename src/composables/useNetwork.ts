import { reactive, computed } from 'vue'

interface NetworkState {
  offline: boolean
  gatewayOffline: boolean
}

const state = reactive<NetworkState>({
  offline: false,
  gatewayOffline: false,
})

export function useNetwork() {
  function goOffline(options?: { gateway?: boolean }) {
    state.offline = true
    state.gatewayOffline = options?.gateway ?? false
  }

  function recover() {
    state.offline = false
    state.gatewayOffline = false
  }

  return {
    state,
    isOffline: computed(() => state.offline),
    goOffline,
    recover,
  }
}
