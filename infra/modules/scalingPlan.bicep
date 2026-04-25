@description('Azure region for the scaling plan resource')
param location string

@description('Name of the existing pooled host pool to attach the scaling plan to')
param hostPoolName string

@description('Resource group of the existing pooled host pool')
param hostPoolResourceGroupName string = resourceGroup().name

@description('Scaling plan name')
param scalingPlanName string

@description('Friendly name for the scaling plan')
param scalingPlanFriendlyName string = ''

@description('Description for the scaling plan')
param scalingPlanDescription string = ''

@description('Time zone for pooled schedules')
param scalingPlanTimeZone string = 'UTC'

@description('Optional exclusion tag for hosts that should be excluded from scaling actions')
param scalingPlanExclusionTag string = ''

@description('Weekday ramp-up start time in HH:mm format')
param weekdayRampUpStartTime string = '06:00'

@description('Weekday peak start time in HH:mm format')
param weekdayPeakStartTime string = '09:00'

@description('Weekday ramp-down start time in HH:mm format')
param weekdayRampDownStartTime string = '17:00'

@description('Weekday off-peak start time in HH:mm format')
param weekdayOffPeakStartTime string = '20:00'

@description('Weekend ramp-up start time in HH:mm format')
param weekendRampUpStartTime string = '08:00'

@description('Weekend peak start time in HH:mm format')
param weekendPeakStartTime string = '10:00'

@description('Weekend ramp-down start time in HH:mm format')
param weekendRampDownStartTime string = '15:00'

@description('Weekend off-peak start time in HH:mm format')
param weekendOffPeakStartTime string = '18:00'

@description('Load-balancing algorithm used during ramp-up')
@allowed(['BreadthFirst', 'DepthFirst'])
param rampUpLoadBalancingAlgorithm string = 'BreadthFirst'

@description('Load-balancing algorithm used during peak')
@allowed(['BreadthFirst', 'DepthFirst'])
param peakLoadBalancingAlgorithm string = 'BreadthFirst'

@description('Load-balancing algorithm used during ramp-down')
@allowed(['BreadthFirst', 'DepthFirst'])
param rampDownLoadBalancingAlgorithm string = 'DepthFirst'

@description('Load-balancing algorithm used during off-peak')
@allowed(['BreadthFirst', 'DepthFirst'])
param offPeakLoadBalancingAlgorithm string = 'DepthFirst'

@description('Minimum percentage of session hosts to keep running during ramp-up and off-peak periods')
@minValue(0)
@maxValue(100)
param minimumHostsPct int = 20

@description('Capacity threshold percentage that triggers ramp-up and ramp-down transitions')
@minValue(1)
@maxValue(100)
param capacityThresholdPct int = 75

@description('How long to wait before stopping hosts during ramp-down')
@minValue(0)
param rampDownWaitTimeMinutes int = 30

@description('When a host can be stopped during ramp-down')
@allowed(['ZeroSessions', 'ZeroActiveSessions'])
param rampDownStopHostsWhen string = 'ZeroSessions'

@description('Whether users should be forced off during ramp-down')
param rampDownForceLogoffUsers bool = false

@description('Notification shown to users before forced logoff during ramp-down')
param rampDownNotificationMessage string = 'This session host will be stopped by the Azure Virtual Desktop scaling plan.'

@description('Tags for the scaling plan resource')
param tags object = {}

var hostPoolArmPath = resourceId(hostPoolResourceGroupName, 'Microsoft.DesktopVirtualization/hostPools', hostPoolName)
var effectiveFriendlyName = empty(scalingPlanFriendlyName) ? 'AVD Scaling Plan' : scalingPlanFriendlyName
var weekdayRampUpTime = {
  hour: int(split(weekdayRampUpStartTime, ':')[0])
  minute: int(split(weekdayRampUpStartTime, ':')[1])
}
var weekdayPeakTime = {
  hour: int(split(weekdayPeakStartTime, ':')[0])
  minute: int(split(weekdayPeakStartTime, ':')[1])
}
var weekdayRampDownTime = {
  hour: int(split(weekdayRampDownStartTime, ':')[0])
  minute: int(split(weekdayRampDownStartTime, ':')[1])
}
var weekdayOffPeakTime = {
  hour: int(split(weekdayOffPeakStartTime, ':')[0])
  minute: int(split(weekdayOffPeakStartTime, ':')[1])
}
var weekendRampUpTime = {
  hour: int(split(weekendRampUpStartTime, ':')[0])
  minute: int(split(weekendRampUpStartTime, ':')[1])
}
var weekendPeakTime = {
  hour: int(split(weekendPeakStartTime, ':')[0])
  minute: int(split(weekendPeakStartTime, ':')[1])
}
var weekendRampDownTime = {
  hour: int(split(weekendRampDownStartTime, ':')[0])
  minute: int(split(weekendRampDownStartTime, ':')[1])
}
var weekendOffPeakTime = {
  hour: int(split(weekendOffPeakStartTime, ':')[0])
  minute: int(split(weekendOffPeakStartTime, ':')[1])
}

resource scalingPlan 'Microsoft.DesktopVirtualization/scalingPlans@2025-10-10' = {
  name: scalingPlanName
  location: location
  tags: tags
  properties: {
    friendlyName: effectiveFriendlyName
    description: empty(scalingPlanDescription) ? null : scalingPlanDescription
    exclusionTag: empty(scalingPlanExclusionTag) ? null : scalingPlanExclusionTag
    hostPoolType: 'Pooled'
    timeZone: scalingPlanTimeZone
    hostPoolReferences: [
      {
        hostPoolArmPath: hostPoolArmPath
        scalingPlanEnabled: true
      }
    ]
    schedules: [
      {
        name: 'Weekdays'
        daysOfWeek: [
          'Monday'
          'Tuesday'
          'Wednesday'
          'Thursday'
          'Friday'
        ]
        rampUpStartTime: weekdayRampUpTime
        peakStartTime: weekdayPeakTime
        rampDownStartTime: weekdayRampDownTime
        offPeakStartTime: weekdayOffPeakTime
        rampUpLoadBalancingAlgorithm: rampUpLoadBalancingAlgorithm
        peakLoadBalancingAlgorithm: peakLoadBalancingAlgorithm
        rampDownLoadBalancingAlgorithm: rampDownLoadBalancingAlgorithm
        offPeakLoadBalancingAlgorithm: offPeakLoadBalancingAlgorithm
        rampUpMinimumHostsPct: minimumHostsPct
        rampDownMinimumHostsPct: minimumHostsPct
        rampUpCapacityThresholdPct: capacityThresholdPct
        rampDownCapacityThresholdPct: capacityThresholdPct
        rampDownWaitTimeMinutes: rampDownWaitTimeMinutes
        rampDownStopHostsWhen: rampDownStopHostsWhen
        rampDownForceLogoffUsers: rampDownForceLogoffUsers
        rampDownNotificationMessage: rampDownNotificationMessage
      }
      {
        name: 'Weekends'
        daysOfWeek: [
          'Saturday'
          'Sunday'
        ]
        rampUpStartTime: weekendRampUpTime
        peakStartTime: weekendPeakTime
        rampDownStartTime: weekendRampDownTime
        offPeakStartTime: weekendOffPeakTime
        rampUpLoadBalancingAlgorithm: rampUpLoadBalancingAlgorithm
        peakLoadBalancingAlgorithm: peakLoadBalancingAlgorithm
        rampDownLoadBalancingAlgorithm: rampDownLoadBalancingAlgorithm
        offPeakLoadBalancingAlgorithm: offPeakLoadBalancingAlgorithm
        rampUpMinimumHostsPct: minimumHostsPct
        rampDownMinimumHostsPct: minimumHostsPct
        rampUpCapacityThresholdPct: capacityThresholdPct
        rampDownCapacityThresholdPct: capacityThresholdPct
        rampDownWaitTimeMinutes: rampDownWaitTimeMinutes
        rampDownStopHostsWhen: rampDownStopHostsWhen
        rampDownForceLogoffUsers: rampDownForceLogoffUsers
        rampDownNotificationMessage: rampDownNotificationMessage
      }
    ]
  }
}

output scalingPlanId string = scalingPlan.id
output scalingPlanName string = scalingPlan.name
output hostPoolArmPath string = hostPoolArmPath
