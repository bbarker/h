{module, inject} = require('angular-mock')

assert = chai.assert


describe 'h:directives.simple-search', ->
  $compile = null
  $element = null
  $scope = null
  fakeWindow = null
  isolate = null

  before ->
    angular.module('h', [])
    require('../simple-search')

  beforeEach module('h')

  beforeEach inject (_$compile_, _$rootScope_) ->
    $compile = _$compile_
    $scope = _$rootScope_.$new()

    $scope.update = sinon.spy()
    $scope.clear = sinon.spy()

    template= '''
    <div class="simpleSearch"
          query="query"
          on-search="update(query)"
          on-clear="clear()">
    </div>
    '''

    $element = $compile(angular.element(template))($scope)
    $scope.$digest()
    isolate = $element.isolateScope()

  it 'updates the search-bar', ->
    $scope.query = "Test query"
    $scope.$digest()
    assert.equal(isolate.searchtext, $scope.query)

  it 'calls the given search function', ->
    isolate.searchtext = "Test query"
    isolate.$digest()
    $element.find('form').triggerHandler('submit')
    sinon.assert.calledWith($scope.update, "Test query")

  it 'invokes callbacks when the input model changes', ->
    $scope.query = "Test query"
    $scope.$digest()
    sinon.assert.calledOnce($scope.update)
    $scope.query = ""
    $scope.$digest()
    sinon.assert.calledOnce($scope.clear)

  it 'adds a class to the form when there is no input value', ->
    $form = $element.find('.simple-search-form')
    assert.include($form.prop('className'), 'simple-search-inactive')

  it 'removes the class from the form when there is an input value', ->
    $scope.query = "Test query"
    $scope.$digest()

    $form = $element.find('.simple-search-form')
    assert.notInclude($form.prop('className'), 'simple-search-inactive')
